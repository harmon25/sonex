defmodule DiscoverState do
  defstruct  socket: nil, players: [], player_count: 0
  @type t :: %__MODULE__{socket: pid, players: list, player_count: integer}
end

defmodule Sonex.Discovery do
  use GenServer

@playersearch ~S"""
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: 1
ST: urn:schemas-upnp-org:device:ZonePlayer:1
"""
  @multicastaddr {239,255,255,250}
  @multicastport 1900

  def start_link() do
    GenServer.start_link(__MODULE__, %DiscoverState{}, name: __MODULE__)
  end

  def init(%DiscoverState{} = state) do
    # not really sure why i need an IP, does not seem to work on 0.0.0.0 after some timeout occurs...
    # needs to be passed a interface IP that is the same lan as sonos DLNA multicasts
    ip_addr = Application.get_env(:sonex, :dlna_listen_addr)

    {:ok, socket} = :gen_udp.open(0, [:binary,
                                      :inet, {:ip, ip_addr },
                                      {:active, true},
                                      {:multicast_if, ip_addr},
                                      {:multicast_ttl, 4},
                                      {:add_membership, {@multicastaddr, ip_addr} }])

     #fire two udp discover packets immediatly
     :gen_udp.send(socket, @multicastaddr, @multicastport , @playersearch )
     :gen_udp.send(socket, @multicastaddr, @multicastport , @playersearch )
     {:ok, %DiscoverState{state | socket: socket}}
  end


  def terminate(_reason, %DiscoverState{socket: socket} = state) when socket != nil do
    #require Logger
    #Logger.info("closing socket")
    :ok = :gen_udp.close(socket)
  end

  @doc """
  Fires a UPNP discover packet onto the LAN,
  all Sonos devices should respond, refresing player attributes stored in state
  """
  def discover() do
   GenServer.cast( __MODULE__, :discover)
  end

  @doc """
  Retuns a single Sonos Player Struct, or nil of does not exist.
  """
  def playerByName(name) do
    GenServer.call(__MODULE__, {:player_by_name, name})
  end


  @doc """
  Retuns a single Sonos Player Struct, or nil of does not exist.
  """
  def zoneByName(name) do
    GenServer.call(__MODULE__, {:zone_by_name, name})
  end

  @doc """
  Retuns a list of all Sonos Device Structs discovered on the LAN
  """
  def players() do
    GenServer.call(__MODULE__, :players)
  end

  @doc """
  Retuns returns number of devices discoverd on lan
  """
  def count() do
    GenServer.call(__MODULE__, :count)
  end


  @doc """
  Fires a UPNP discover packet onto the LAN,
  all Sonos devices should respond, refresing player attributes stored in state
  """
  def zones() do
   GenServer.call( __MODULE__, :zones)
  end

  @doc """
  Terminates Sonex.Discovery GenServer
  """
  def kill() do
   GenServer.stop(__MODULE__, "Done")
  end

  def handle_call({:player_by_name, name}, _from, %DiscoverState{players: players_list} = state) do
    res =
    Enum.find(players_list, nil,
      fn player ->
        player.name == name
      end
    )
     {:reply, res, state}
  end

  def handle_call(:zones, _from, %DiscoverState{} = state)  do
      zone_coordinators = Enum.filter(state.players, fn(player) ->
        player.uuid == player.coordinator_uuid
      end)
     {:reply, zone_coordinators , state}
  end

  def handle_call({:zone_by_name, name}, _from, %DiscoverState{} = state)  do
      players_in_zone =
      Enum.filter(state.players, fn(player) -> player.uuid == player.coordinator_uuid end)
      |> Enum.filter(fn(coordinator)-> coordinator.name == name end)
      |> case do
        [] ->
          {:error, "Not a Coordintator"}
       [zone] ->
          Enum.filter(state.players, fn(p) -> zone.uuid == p.coordinator_uuid end)
          |> Enum.reverse()
      end
     {:reply, players_in_zone , state}
  end

  def handle_call(:players, _from, %DiscoverState{} = state)  do
     {:reply, state.players , state}
  end

  def handle_call(:count, _from, state) do
    {:reply, state.player_count, state}
  end

  def handle_cast(:kill, state) do
     :ok = :gen_udp.close(state.socket)
    {:noreply, state}
  end

  def handle_cast(:discover, state) do
    :gen_udp.send(state.socket, @multicastaddr, @multicastport , @playersearch )
    {:noreply, state }
  end

  def handle_info({:udp, socket, ip, _fromport, packet}, %DiscoverState{players: players_list} = state) do
    this_player = parse_upnp(ip, packet)
    #IO.puts "GOT PACKET:"
    #IO.inspect players_list
    #IO.inspect this_player.uuid

    case(knownplayer?(players_list, this_player.uuid)) do
      # when it is a new player
      nil ->
      #  IO.puts "NEW PLAYER?"
        atts = attributes(this_player)
        {_, zone_coordinator, _} = group_attributes(this_player)
      #  player = %SonosDevice{ this_player | name: name, icon: icon, config: config, coordinator_uuid: zone_coordinator }
        #send discovered event
        Sonex.PlayerMonitor.create(build(this_player.uuid, this_player.ip, zone_coordinator,  atts))
        #GenEvent.notify(Sonex.EventMngr, {:discovered, player})
        #GenEvent.notify(Sonex.EventMngr, {:start, player})
        new_players = [this_player | players_list ]
        #new_players = [this_player.uuid | players_list]
        {:noreply, %DiscoverState{state | players: new_players , player_count: Enum.count(new_players)}}
      #when know the player
      player_index ->
        IO.puts "UPDATE PLAYER:"
        {name, icon, config} = attributes(this_player)
        {_, zone_coordinator, _} = group_attributes(this_player)
        updated_player = %SonosDevice{ this_player | name: name, icon: icon, config: config, coordinator_uuid: zone_coordinator }
        {:noreply, %DiscoverState{state | players: List.replace_at(players_list, player_index, updated_player)}}

    end
  end

  defp build(id, ip, coord_id, {name, icon, config}) do
    new_player = %ZonePlayer{}
    %ZonePlayer{new_player | id: id, name: name,  coordinator_id: coord_id, info: %{new_player.info | ip: ip, icon: icon, config: config }}
  end


  defp knownplayer?(players, uuid) do
    Enum.find_index(players, fn player -> player.uuid == uuid end)
  end

  defp attributes(%SonosDevice{} = player) do
    import SweetXml
   {:ok, res_body} = Sonex.SOAP.build(:device, "GetZoneAttributes") |> Sonex.SOAP.post(player)
   { xpath(res_body,  ~x"//u:GetZoneAttributesResponse/CurrentZoneName/text()"s),
     xpath(res_body, ~x"//u:GetZoneAttributesResponse/CurrentIcon/text()"s),
     xpath(res_body, ~x"//u:GetZoneAttributesResponse/CurrentConfiguration/text()"i)
    }
  end

  defp group_attributes(%SonosDevice{} = player) do
     import SweetXml
    {:ok, res_body} =
      Sonex.SOAP.build(:zone, "GetZoneGroupAttributes")
      |> Sonex.SOAP.post(player)

    zone_name = xpath(res_body, ~x"//u:GetZoneGroupAttributesResponse/CurrentZoneGroupName/text()"s)
    zone_id = xpath(res_body, ~x"//u:GetZoneGroupAttributesResponse/CurrentZoneGroupID/text()"s)
    zone_players_list =  xpath(res_body, ~x"//u:GetZoneGroupAttributesResponse/CurrentZonePlayerUUIDsInGroup/text()"ls)
    case(zone_name) do
      # this zone is not in a gruop
      "" -> {nil, nil, []}
       _ ->
         [clean_zone, _] = String.split(zone_id, ":")
         {zone_name, clean_zone, zone_players_list}
    end
  end


  def zone_group_state(%SonosDevice{} = player) do
    import SweetXml
    {:ok, res} = Sonex.SOAP.build(:zone, "GetZoneGroupState", [])
    |> Sonex.SOAP.post(player)

    xpath(res, ~x"//ZoneGroupState/text()"s)
    |> xpath(~x"//ZoneGroups/ZoneGroup"l, coordinator_uuid: ~x"//./@Coordinator"s, members:
      [
        ~x"//./ZoneGroup/ZoneGroupMember"el,
        name: ~x"//./@ZoneName"s,
        uuid: ~x"//./@UUID"s,
        addr: ~x"//./@Location"s,
        config: ~x"//./@Configuration"i,
        icon: ~x"//./@Icon"s,
      ] )


  end

  defp parse_upnp(ip, good_resp) do
    split_resp = String.split(good_resp, "\r\n")
    "SERVER: Linux UPnP/1.0 " <> vers_model = Enum.fetch!(split_resp, 4)
    [version, model_raw] = String.split(vers_model)
    model = String.lstrip(model_raw, ?() |> String.rstrip(?))
    "USN: uuid:" <> usn = Enum.fetch!(split_resp, 6)
    uuid = String.split(usn, "::") |> Enum.at(0)
    "X-RINCON-HOUSEHOLD: Sonos_" <> household = Enum.fetch!(split_resp, 7)
    %SonosDevice{ip: :inet.ntoa(ip), version: version, model: model, uuid: uuid, household: household }
  end

end
