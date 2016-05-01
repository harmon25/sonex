defmodule Sonex.SubMngr do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{handler: nil, timers: [], port: 8700}, name: __MODULE__)
  end

  def init(state) do

     dispatch = :cowboy_router.compile([{ :_, [
                                            {"/ZoneGroupTopology", Sonex.SubHandlerZone, []},
                                            {"/RenderingControl", Sonex.SubHandlerRender, []},
                                            {"/AVTransport", Sonex.SubHandlerAV, []}

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

  def handle_call(:protocol_opts, _from, _state) do
    {:reply, :ok, _state}
  end


  def handle_call({:subscribe, device, service}, _from, state) do
     response = subscribe_req(device, service, state.port)
     {:ok, timer} = :timer.send_interval(3550000, {:sub_interval, device, service} )
     new_timers = state.timers ++ [timer]
    {:reply, response, %{state| timers: new_timers} }
  end

  def handle_info({:sub_interval, device, service}, state ) do
    subscribe_req(device, service, state.port)
    {:noreply, state}
  end


  defp subscribe_req(device, service, port) do
    uri = "http://#{device.ip}:1400#{service.event}"
    req_headers = sub_headers(port, service)
    valid_resp =
    HTTPoison.request!(:subscribe, uri, "", req_headers)
    |> handle_sub_response()

    resp =
    case(valid_resp) do
       {:ok, res_body} ->
         {:ok, "Subscription successful"}
       {:error, err_msg} ->
         {:error, err_msg}
    end
  end


  defp sub_headers(cb_port, serv) do
    {a,b,c,d} = Application.get_env(:sonex, :dlna_listen_addr)
    cb_uri =
    case(serv) do
      %{type: "urn:schemas-upnp-org:service:ZoneGroupTopology:1"} ->
          "<http://#{a}.#{b}.#{c}.#{d}:#{cb_port}/ZoneGroupTopology>"
      %{type: "urn:schemas-upnp-org:service:RenderingControl:1"} ->
        "<http://#{a}.#{b}.#{c}.#{d}:#{cb_port}/RenderingControl>"
      %{type: "urn:schemas-upnp-org:service:AVTransport:1"} ->
        "<http://#{a}.#{b}.#{c}.#{d}:#{cb_port}/AVTransport>"
    end
    %{"CALLBACK"=> cb_uri, "NT"=> "upnp:event", "TIMEOUT"=> "Second-3600", "Content-Type"=>"text/xml; charset=\"utf-8\""}
  end

  defp handle_sub_response(resp) do
    case(resp) do
      %HTTPoison.Response{status_code: 200, body: res_body} ->
        {:ok, res_body}
      %HTTPoison.Response{status_code: 500, body: err_body} ->
        {:error, Sonex.SOAP.parse_soap_error(err_body)}
    end
  end

end
