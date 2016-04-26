defmodule SonosDevice do
  defstruct  ip: nil, model: nil, usnID: nil, household: nil, name: nil, config: nil, icon: nil, version: nil
  @type t :: %__MODULE__{ip: String.t, model: String.t, usnID: String.t, household: String.t, name: String.t, config: integer, icon: String.t, version: String.t}
end

defmodule DiscoverState do
  defstruct  socket: nil, players: [], player_count: 0
  @type t :: %__MODULE__{socket: pid, players: list(SonosDevice.t), player_count: integer}
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

  def discover() do
   GenServer.cast( __MODULE__, :discover)
  end

  def playerByName(name) do
    GenServer.call(__MODULE__, {:player_by_name, name})
  end

  def players() do
    GenServer.call(__MODULE__, :players)
  end

  def count() do
    GenServer.call(__MODULE__, :count)
  end

  def kill() do
   GenServer.stop(__MODULE__, "Done")
  end

  def handle_call({:player_by_name, name}, _from, %DiscoverState{players: players_list} = state) do
    res =
    Enum.find(players_list, nil,
      fn player -> 
        player.name == name end
    )
     {:reply, {:ok, res} , state}
  end

  def handle_call(:players, _from, %DiscoverState{} = state)  do
     {:reply, {:ok, state.players} , state}
  end

  def handle_call(:count, _from, state) do
    {:reply, state.player_count, state}
  end

  def handle_cast(:kill, state) do
     :ok = :gen_udp.close(state.socket)
    {:noreply, state}
  end

  def handle_call(:discovered?, _from, state) do
    {:reply, state.discovered, state}
  end

  def handle_cast(:discover, state) do
    :gen_udp.send(state.socket, @multicastaddr, @multicastport , @playersearch )
    {:noreply, state }
  end

  def handle_info({:udp, socket, ip, _fromport, packet}, %DiscoverState{players: players_list} = state) do
    this_player = parse_upnp(ip, packet)
    existing_player = Enum.find_index(players_list, fn player -> player.usnID == this_player.usnID end)
    case(existing_player) do
      player_index when is_nil(player_index) == false ->
        {name, icon, config} = attributes(this_player)
        updated_player = %SonosDevice{ this_player | name: name, icon: icon, config: config } 
        {:noreply, %DiscoverState{state | players: List.replace_at(players_list, player_index, updated_player)}}
      player_index when is_nil(player_index) == true ->
        {name, icon, config} = attributes(this_player)
        new_players = players_list ++ [%SonosDevice{ this_player | name: name, icon: icon, config: config }]
        {:noreply, %DiscoverState{state | players: new_players, player_count: Enum.count(new_players)}}
    end
  end

  defp attributes(%SonosDevice{} = player) do
    import SweetXml
   {:ok, res_body} = Sonex.SOAP.build(:device, "GetZoneAttributes") |> Sonex.SOAP.post(player)
   { xpath(res_body,  ~x"//u:GetZoneAttributesResponse/CurrentZoneName/text()"s), 
     xpath(res_body, ~x"//u:GetZoneAttributesResponse/CurrentIcon/text()"s),
     xpath(res_body, ~x"//u:GetZoneAttributesResponse/CurrentConfiguration/text()"i)
    }
  end

  defp parse_upnp(ip, good_resp) do
    split_resp = String.split(good_resp, "\r\n")
    "SERVER: Linux UPnP/1.0 " <> vers_model = Enum.fetch!(split_resp, 4)
    [version, model_raw] = String.split(vers_model)
    model = String.lstrip(model_raw, ?() |> String.rstrip(?))
    "USN: uuid:RINCON_" <> usn = Enum.fetch!(split_resp, 6)
    usn_id = String.split(usn, "::") |> Enum.at(0)
    "X-RINCON-HOUSEHOLD: Sonos_" <> household = Enum.fetch!(split_resp, 7)
    %SonosDevice{ip: format_ip(ip), version: version, model: model, usnID: usn_id, household: household }
  end

  defp format_ip ({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end


end


