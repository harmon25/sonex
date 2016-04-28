defmodule Sonex.SubHandler do
  def init(_type, req, []) do
      {:ok, req, :no_state}
  end

  def handle(request, state) do
     import SweetXml
     {:ok, data, req1 } = :cowboy_req.body(request)


    {:undefined, "uuid:" <> uuid_raw, req2 } = :cowboy_req.parse_header(<<"sid">>, req1)
    {:undefined, seq, req3 } = :cowboy_req.parse_header(<<"seq">>, req2)
    [header, main, sub_id ] = String.split(uuid_raw, "_")
    uuid = header <> "_" <> main
    
    clean_xml =
    data
    |> clean_resp("&amp;quot;", "\"")
    |> clean_resp("&amp;lt;", "<")
    |> clean_resp("&amp;gt;", ">")
    |> clean_resp("&lt;", "<")
    |> clean_resp("&gt;", ">")
    |> clean_resp("&quot;", "\"")


    #"<dc:title> </dc:title>"
    
    IO.puts uuid
    IO.puts sub_id
    IO.puts seq
    #IO.puts clean_xml
    event_xml = xpath(clean_xml, ~x"//e:propertyset/e:property/LastChange/Event"e)
    #trans_state = xpath(clean_xml, ~x"//LastChange/Event/@xmlns"s)
    #play_mode = xpath(data, ~x"//e:propertyset/e:property/LastChange/Event/InstanceID/CurrentPlayMode/@val"s)
    IO.inspect event_xml
    #IO.inspect trans_state

    { :ok, reply } = :cowboy_req.reply(200, req3 )

    
    # handle/2 returns a tuple starting containing :ok, the reply, and the 
    # current state of the handler.
    {:ok, reply, state}

   end


   defp clean_resp(resp, to_clean, replace_with) do
      String.replace(resp, to_clean, replace_with)
   end

  def dl_headers(request) do  
    {headers, req2 } = :cowboy_req.headers(request)
    Enum.map(headers, fn item -> IO.inspect(item) end)
  end

  # Termination handler.  Usually you don't do much with this.  If things are breaking,
  # try uncommenting the output lines here to get some more info on what's happening.
  def terminate(reason, request, state) do
    #IO.puts("Terminating for reason: #{inspect(reason)}")
    #IO.puts("Terminating after request: #{inspect(request)}")
    #IO.puts("Terminating with state: #{inspect(state)}")
    :ok
  end

end


defmodule Sonex.SubMngr do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
     dispatch = :cowboy_router.compile([{ :_, [ {"/", Sonex.SubHandler, []} ] }])
     port = 8700
     { :ok, handler } = :cowboy.start_http(:http, 
                            50,
                           [{:port, port }],  
                           [{ :env, [{:dispatch, dispatch}]}]
                           ) 

     IO.inspect Sonex.Discovery.players
     #{:ok, sub_interval } = :timer.apply_interval(5000, IO, :inspect, ["HI from interval"] )
     #IO.inspect handler
     {:ok, %{handler: handler, port: port} }
  end


   
  def subscribe(device, service) do
    GenServer.cast( __MODULE__, {:subscribe, device,  service})
  end

  def protocol_opts() do
    GenServer.call( __MODULE__, :protocol_opts)
  end

  def handle_call(:protocol_opts, _from, state) do
    {:reply, :ok, state}
  end


  def handle_cast({:subscribe, device, serice}, state) do
     uri = "http://#{device.ip}:1400#{serice.event}"
     req_headers = sub_headers(state.port)
     resp = HTTPoison.request! :subscribe, uri, "", req_headers
     case(handle_sub_response(resp)) do
        {:ok, res_body} ->
          IO.puts res_body
        {:error, err_msg} ->
          IO.puts err_msg
     end
    {:noreply, state }
  end

  defp sub_headers(cb_port) do
    {a,b,c,d} = Application.get_env(:sonex, :dlna_listen_addr)
    %{"CALLBACK"=>"<http://#{a}.#{b}.#{c}.#{d}:#{cb_port}>", "NT"=> "upnp:event", "TIMEOUT"=> "Second-120", "Content-Type"=>"text/xml; charset=\"utf-8\""}
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