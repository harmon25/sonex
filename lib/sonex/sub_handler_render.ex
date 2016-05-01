defmodule Sonex.SubHandlerRender do
  import SweetXml
  alias Sonex.SubHelpers

  def init(_type, req, []) do
      {:ok, req, :no_state}
  end

  def handle(request, state) do

     {:ok, data, _ } = :cowboy_req.body(request)

    sub_info_base = SubHelpers.create_sub_data(request, "RCS")


    clean_xml = SubHelpers.clean_xml_str(data)
    #"<dc:title> </dc:title>"
    #IO.puts clean_xml

    #IO.puts clean_xml
    event_xml = xpath(clean_xml, ~x"//e:propertyset/e:property/LastChange/*[1]"e)
    #volume_state = xpath(event_xml, ~x"//Event/InstanceID/Volume/@val"il)
    #mute_info = xpath(event_xml, ~x"//Event/InstanceID/Mute/@val"il)
    sub_content_map =
    get_volume(%{}, event_xml)
    |> get_mute(event_xml)
    |> get_bass(event_xml)
    |> get_treble(event_xml)
    |> get_loudness(event_xml)

    sub_info = %SubData{sub_info_base | content: sub_content_map}


    IO.inspect sub_info


    { :ok, reply } = :cowboy_req.reply(200, request )


    # handle/2 returns a tuple starting containing :ok, the reply, and the
    # current state of the handler.
    {:ok, reply, state}

   end


   defp get_volume(map, xml) do
     case(xpath(xml, ~x"//Event/InstanceID/Volume"e)) do
       nil -> map
       _ ->
         [master_vol, left_vol, right_vol] = xpath(xml, ~x"//Event/InstanceID/Volume/@val"sl)
         Map.put_new(map, :volume, %{m: master_vol, l: left_vol, r: right_vol } )
     end
   end

   defp get_mute(map, xml) do
     case(xpath(xml, ~x"//Event/InstanceID/Mute"e)) do
       nil ->  map
       _ ->
         [master_m, _, _] = xpath(xml, ~x"//Event/InstanceID/Mute/@val"sl)
         case(master_m) do
           "0" -> Map.put_new(map, :mute, false )
           "1" -> Map.put_new(map, :mute, true )
         end
     end
   end

   defp get_treble(map, xml) do
     case(xpath(xml, ~x"//Event/InstanceID/Treble"e)) do
       nil -> map
       _ -> Map.put_new(map, :treble, xpath(xml, ~x"//Event/InstanceID/Treble/@val"i))
     end
   end

   defp get_bass(map, xml) do
     case(xpath(xml, ~x"//Event/InstanceID/Bass"e)) do
       nil ->  map
       _ ->  Map.put_new(map, :bass, xpath(xml, ~x"//Event/InstanceID/Bass/@val"i))

     end
   end

   defp get_loudness(map, xml) do
     case(xpath(xml, ~x"//Event/InstanceID/Loudness"e)) do
       nil -> map
       _ ->
         case(xpath(xml, ~x"//Event/InstanceID/Loudness/@val"s)) do
           "0" ->  Map.put_new(map, :loudness, false )
           "1" ->  Map.put_new(map, :loudness, true )
         end
     end
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
