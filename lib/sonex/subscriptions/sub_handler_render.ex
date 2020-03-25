defmodule Sonex.SubHandlerRender do
  import SweetXml
  alias Sonex.SubHelpers
  alias Sonex.Network.State

  def init(req, _opts) do
    handle(req, %{})
    {:ok, req, :no_state}
  end

  def handle(request, state) do
    {:ok, data, _} = :cowboy_req.read_body(request, %{})

    sub_info_base = SubHelpers.create_sub_data(request, :renderer)

    clean_xml = SubHelpers.clean_xml_str(data)
    event_xml = xpath(clean_xml, ~x"//e:propertyset/e:property/LastChange/*[1]"e)

    player = %{player_state: player_state} = State.get_player(sub_info_base.from)

    new_state =
      player_state
      |> get_volume(event_xml)
      |> get_mute(event_xml)
      |> get_bass(event_xml)
      |> get_treble(event_xml)
      |> get_loudness(event_xml)

    player = %{player | player_state: new_state}
    State.put_device(player)

    reply = :cowboy_req.reply(200, request)
    {:ok, reply, state}
  end

  defp get_volume(%PlayerState{} = p_state, xml) do
    case(xpath(xml, ~x"//Event/InstanceID/Volume"e)) do
      nil ->
        p_state

      _ ->
        [master_vol, left_vol, right_vol] = xpath(xml, ~x"//Event/InstanceID/Volume/@val"sl)
        %{p_state | volume: %{m: master_vol, l: left_vol, r: right_vol}}
    end
  end

  defp get_mute(%PlayerState{} = p_state, xml) do
    case(xpath(xml, ~x"//Event/InstanceID/Mute"e)) do
      nil ->
        p_state

      _ ->
        [master_m, _, _] = xpath(xml, ~x"//Event/InstanceID/Mute/@val"sl)

        %{p_state | mute: master_m == "1"}
    end
  end

  defp get_treble(%PlayerState{} = p_state, xml) do
    case(xpath(xml, ~x"//Event/InstanceID/Treble"e)) do
      nil ->
        p_state

      _ ->
        %{p_state | treble: xpath(xml, ~x"//Event/InstanceID/Treble/@val"i)}
    end
  end

  defp get_bass(%PlayerState{} = p_state, xml) do
    case(xpath(xml, ~x"//Event/InstanceID/Bass"e)) do
      nil ->
        p_state

      _ ->
        %{p_state | bass: xpath(xml, ~x"//Event/InstanceID/Bass/@val"i)}
    end
  end

  defp get_loudness(%PlayerState{} = p_state, xml) do
    case(xpath(xml, ~x"//Event/InstanceID/Loudness"e)) do
      nil ->
        p_state

      _ ->
        loudness = xpath(xml, ~x"//Event/InstanceID/Loudness/@val"s)
        %{p_state | loudness: loudness == "1"}
    end
  end

  # Termination handler.  Usually you don't do much with this.  If things are breaking,
  # try uncommenting the output lines here to get some more info on what's happening.
  def terminate(_reason, _request, _state) do
    #   IO.puts("Render Terminating for reason: #{inspect(reason)}")
    #    IO.puts("Terminating after request: #{inspect(request)}")
    #    IO.puts("Terminating with state: #{inspect(state)}")
    :ok
  end
end
