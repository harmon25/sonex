defmodule Sonex.SubMngr do
  use GenServer

  @timeout 3600000
  @resub @timeout-60000

  def start_link() do
    GenServer.start_link(__MODULE__, %{handler: nil, subs: [], port: 8700}, name: __MODULE__)
  end

  def init(state) do

     dispatch = :cowboy_router.compile([{ :_, [
                                            {"/ZoneGroupTopology", Sonex.SubHandlerZone, []},
                                            {"/RenderingControl", Sonex.SubHandlerRender, []},
                                            {"/AVTransport", Sonex.SubHandlerAV, []},
                                          #  {"/DeviceProperties", Sonex.SubHandlerDevice, []}

                                              ]
                                       }])
     { :ok, handler } = :cowboy.start_http(:http, 50,
                           [{:port, state.port }],
                           [{ :env, [{:dispatch, dispatch}]}]
                           )

     #IO.inspect Sonex.Discovery.players
     #{:ok, sub_interval } = :timer.apply_interval(5000, IO, :inspect, ["HI from interval"] )
     #IO.inspect handler
     {:ok, %{state | handler: handler} }
  end

  def subscribe(device, service) do
    GenServer.call( __MODULE__, {:subscribe, device,  service})
  end

  def protocol_opts() do
    GenServer.call( __MODULE__, :protocol_opts)
  end

  def handle_call(:protocol_opts, _from, state) do
    {:reply, :ok, state}
  end


  def handle_call({:subscribe, device, service}, _from, state) do
     {:ok, sub_id} = subscribe_req(device, service, state.port)
     # resubscribe 1 minute before sub timesout
     {:ok, timer} = :timer.send_interval(@resub, {:sub_interval, device, service} )
    {:reply, sub_id, %{state| subs: [ %{timer: timer, name: device.name, sub_id: sub_id , type: service.event} | state.subs] } }
  end

  def handle_call({:unsubscribe, device, service, sub_id}, _from, %{subs: sub_list} = state) do
     {:ok, sub_id} = unsubscribe_req(device, service, sub_id)
     to_unsub = Enum.find(sub_list, fn(s)-> s == sub_id end )
     :timer.cancel(to_unsub.timer)
     new_subs = Enum.filter(sub_list, fn(s)-> s != sub_id end)
     {:reply, :ok, %{state| subs: new_subs } }
  end

  def handle_info({:sub_interval, device, service}, state ) do
    subscribe_req(device, service, state.port)
    {:noreply, state}
  end


  defp subscribe_req(device, service, port) do
    uri = "http://#{device.info.ip}:1400#{service.event}"
    req_headers = sub_headers(port, service)
    HTTPoison.request!(:subscribe, uri, "", req_headers)
    |> handle_sub_response()
  end

  defp unsubscribe_req(device, service, sub_id) do
    uri = "http://#{device.info.ip}:1400#{service.event}"
    req_headers = %{"SID"=> sub_id }
    valid_resp =
    HTTPoison.request!(:unsubscribe, uri, "" ,req_headers)
    |> handle_sub_response()

    case(valid_resp) do
       {:ok, _res_body} ->
         {:ok, %{msg: "Unsubscription successful"}}
       {:error, err_msg} ->
         {:error, err_msg}
    end
  end


  defp sub_headers(port, serv) do
    {a,b,c,d} =
     if Application.get_env(:sonex, :dlna_listen_addr) do
       Application.get_env(:sonex, :dlna_listen_addr)
     else
       Sonex.Discovery.get_ip(Application.get_env(:sonex, :dlna_listen_int))
     end

    cb_uri =
    case(serv) do
      %{type: "urn:schemas-upnp-org:service:ZoneGroupTopology:1"} ->
          "<http://#{a}.#{b}.#{c}.#{d}:#{port}/ZoneGroupTopology>"
      %{type: "urn:schemas-upnp-org:service:RenderingControl:1"} ->
        "<http://#{a}.#{b}.#{c}.#{d}:#{port}/RenderingControl>"
      %{type: "urn:schemas-upnp-org:service:AVTransport:1"} ->
        "<http://#{a}.#{b}.#{c}.#{d}:#{port}/AVTransport>"
      %{type: "urn:schemas-upnp-org:service:DeviceProperties:1"} ->
          "<http://#{a}.#{b}.#{c}.#{d}:#{port}/DeviceProperties>"
    end
    %{"CALLBACK"=> cb_uri, "NT"=> "upnp:event", "TIMEOUT"=> "Second-#{div(@timeout, 1000)}", "Content-Type"=>"text/xml; charset=\"utf-8\""}
  end

  defp handle_sub_response(resp) do
    case(resp) do
      %HTTPoison.Response{status_code: 200, body: _res_body, headers: headers} ->
        header_map = Map.new(headers)
        "uuid:" <> sub_id = header_map["SID"]
        {:ok, sub_id}
      %HTTPoison.Response{status_code: 500, body: err_body} ->
        {:error, Sonex.SOAP.parse_soap_error(err_body)}
    end
  end

end
