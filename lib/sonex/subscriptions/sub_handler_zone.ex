defmodule Sonex.SubHandlerZone do
  import SweetXml

  alias Sonex.SubHelpers
  alias Sonex.Network.State

  def init(req, _opts) do
    handle(req, %{})

    {:ok, req, :no_state}
  end

  def handle(request, state) do
    {:ok, data, _} = :cowboy_req.read_body(request, %{})

    clean_xml = SubHelpers.clean_xml_str(data)

    zone_info =
      xpath(clean_xml, ~x"//ZoneGroups/ZoneGroup"l,
        coordinator_uuid: ~x"//./@Coordinator"s,
        members: [
          ~x"//./ZoneGroup/ZoneGroupMember"el,
          name: ~x"//./@ZoneName"s,
          uuid: ~x"//./@UUID"s,
          addr: ~x"//./@Location"s,
          config: ~x"//./@Configuration"i,
          icon: ~x"//./@Icon"s
        ]
      )

    Enum.each(zone_info, fn zone_group ->
      Enum.each(zone_group.members, fn member ->
        player = State.get_player(member.uuid)
        player = %{player | coordinator_uuid: zone_group.coordinator_uuid, name: member.name}
        State.put_device(player)
      end)
    end)

    reply = :cowboy_req.reply(200, request)

    # handle/2 returns a tuple starting containing :ok, the reply, and the
    # current state of the handler.
    {:ok, reply, state}
  end

  # Termination handler.  Usually you don't do much with this.  If things are breaking,
  # try uncommenting the output lines here to get some more info on what's happening.
  def terminate(_reason, _request, _state) do
    #    IO.puts("Terminating for reason: #{inspect(reason)}")
    #    IO.puts("Terminating after request: #{inspect(request)}")
    #    IO.puts("Terminating with state: #{inspect(state)}")
    :ok
  end
end
