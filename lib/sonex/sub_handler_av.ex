defmodule Sonex.SubHandlerAV do
  import SweetXml
  alias Sonex.SubHelpers

  def init(_type, req, []) do
      {:ok, req, :no_state}
  end

  def handle(request, state) do

     {:ok, data, _ } = :cowboy_req.body(request)

     sub_info_base = SubHelpers.create_sub_data(request, "AV")


    clean_xml = SubHelpers.clean_xml_str(data)
    #"<dc:title> </dc:title>"
    #IO.puts clean_xml

    #IO.puts clean_xml
    event_xml = xpath(clean_xml, ~x"//e:propertyset/e:property/LastChange/*[1]"e)

   transport_state = xpath(event_xml, ~x"//Event/InstanceID/TransportState/@val"s)
   {title, artist, album}  = track_details(event_xml)
  sub_info = %SubData{sub_info_base |
  content:
        %{current_state: transport_state,
        mode: xpath(event_xml, ~x"//Event/InstanceID/CurrentPlayMode/@val"s),
        current_track: xpath(event_xml, ~x"//Event/InstanceID/CurrentTrack/@val"i),
        tracks_total: xpath(event_xml, ~x"//Event/InstanceID/NumberOfTracks/@val"i),
        track_info: %{title: title, artist: artist, album: album},
        duration: xpath(event_xml, ~x"//Event/InstanceID/CurrentTrackDuration/@val"s)
       }
     }


    IO.inspect sub_info

    { :ok, reply } = :cowboy_req.reply(200, request )


    # handle/2 returns a tuple starting containing :ok, the reply, and the
    # current state of the handler.
    {:ok, reply, state}

   end

   defp track_details(event_xml_element) do
     xml_str = xpath(event_xml_element, ~x"//Event/InstanceID/CurrentTrackMetaData/@val"s)
     case(xml_str) do
       track when track == "" ->
         {nil, nil, nil}
       track ->
        cleaned_track = SubHelpers.clean_xml_str(track)
         {xpath(  cleaned_track, ~x"//DIDL-Lite/item/dc:title/text()"s),
          xpath(  cleaned_track, ~x"//DIDL-Lite/item/dc:creator/text()"s),
          xpath(  cleaned_track, ~x"//DIDL-Lite/item/upnp:album/text()"s)
         }
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
