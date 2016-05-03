defmodule Sonex.SubHandlerZone do
  import SweetXml
  alias Sonex.SubHelpers

  def init(_type, req, []) do
      {:ok, req, :no_state}
  end

  def handle(request, state) do

     {:ok, data, _ } = :cowboy_req.body(request)

    sub_info_base = SubHelpers.create_sub_data(request, :zone)



    clean_xml = SubHelpers.clean_xml_str(data)

    zone_info =
    xpath(clean_xml, ~x"//ZoneGroups/ZoneGroup"l, coordinator_uuid: ~x"//./@Coordinator"s, members:
      [
        ~x"//./ZoneGroup/ZoneGroupMember"el,
        name: ~x"//./@ZoneName"s,
        uuid: ~x"//./@UUID"s,
        addr: ~x"//./@Location"s,
        config: ~x"//./@Configuration"i,
        icon: ~x"//./@Icon"s,
      ] )

    Enum.each(zone_info, fn(zone_group) ->
        Enum.each(zone_group.members, fn(member) ->
            case(GenServer.whereis({:global, {:player, member.uuid }})) do
              nil ->
                IO.puts "#{member.uuid} process not started"
              pid ->
                GenServer.cast(pid, {:set_coordinator, zone_group.coordinator_uuid })
                GenServer.cast(pid, {:set_name, member.name })
            end
          end)
    end)

    sub_info = %SubData{sub_info_base | content: zone_info}

    IO.inspect sub_info

    { :ok, reply } = :cowboy_req.reply(200, request )


    # handle/2 returns a tuple starting containing :ok, the reply, and the
    # current state of the handler.
    {:ok, reply, state}

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
