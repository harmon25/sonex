defmodule Sonex.SubHandlerAV do
  import SweetXml
  alias Sonex.SubHelpers
  alias Sonex.Network.State

  def init(req, _opts) do
    handle(req, %{})
    {:ok, req, :no_state}
  end

  def handle(request, state) do
    {:ok, data, _} = :cowboy_req.read_body(request, %{})
    sub_info_base = SubHelpers.create_sub_data(request, :av)

    clean_xml = SubHelpers.clean_xml_str(data)
    event_xml = xpath(clean_xml, ~x"//e:propertyset/e:property/LastChange/*[1]"e)

    transport_state = xpath(event_xml, ~x"//Event/InstanceID/TransportState/@val"s)
    {title, artist, album} = track_details(event_xml)

    player = %{player_state: player_state} = State.get_player(sub_info_base.from)

    new_state = %{
      player_state
      | current_state: transport_state,
        current_mode: xpath(event_xml, ~x"//Event/InstanceID/CurrentPlayMode/@val"s),
        current_track: xpath(event_xml, ~x"//Event/InstanceID/CurrentTrack/@val"i),
        total_tracks: xpath(event_xml, ~x"//Event/InstanceID/NumberOfTracks/@val"i),
        track_info: %{
          title: title,
          artist: artist,
          album: album,
          duration: xpath(event_xml, ~x"//Event/InstanceID/CurrentTrackDuration/@val"s)
        }
    }

    player = %{player | player_state: new_state}
    State.put_device(player)

    reply = :cowboy_req.reply(200, request)

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

        {xpath(cleaned_track, ~x"//DIDL-Lite/item/dc:title/text()"s),
         xpath(cleaned_track, ~x"//DIDL-Lite/item/dc:creator/text()"s),
         xpath(cleaned_track, ~x"//DIDL-Lite/item/upnp:album/text()"s)}
    end
  end

  # Termination handler.  Usually you don't do much with this.  If things are breaking,
  # try uncommenting the output lines here to get some more info on what's happening.
  def terminate(_reason, _request, _state) do
    #    IO.puts("Terminating for reason: #{inspect(reason)}")
    #   IO.puts("Terminating after request: #{inspect(request)}")
    #   IO.puts("Terminating with state: #{inspect(state)}")
    :ok
  end
end
