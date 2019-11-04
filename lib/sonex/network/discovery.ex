defmodule DiscoverState do
  defstruct socket: nil, state: :starting

  @type t :: %__MODULE__{socket: pid}
end

alias Sonex.Network.State

defmodule Sonex.Discovery do
  use GenServer

  require Logger

  @playersearch ~S"""
  M-SEARCH * HTTP/1.1
  HOST: 239.255.255.250:1900
  MAN: "ssdp:discover"
  MX: 1
  ST: urn:schemas-upnp-org:device:ZonePlayer:1
  """
  @multicastaddr {239, 255, 255, 250}
  @multicastport 1900

  @polling_duration 60_000

  def start_link() do
    GenServer.start_link(__MODULE__, %DiscoverState{}, name: __MODULE__)
  end

  def init(%DiscoverState{} = state) do
    # not really sure why i need an IP, does not seem to work on 0.0.0.0 after some timeout occurs...
    # needs to be passed a interface IP that is the same lan as sonos DLNA multicasts

    state = attempt_network_init(state)

    {:ok, state}
  end

  def terminate(_reason, %DiscoverState{socket: socket} = _state) when socket != nil do
    :ok = :gen_udp.close(socket)
  end

  @doc """
  Fires a UPNP discover packet onto the LAN,
  all Sonos devices should respond, refresing player attributes stored in state
  """
  def discover() do
    GenServer.cast(__MODULE__, :discover)
  end

  @doc """
  Returns true if devices were discovered on lan
  """
  def discovered?() do
    GenServer.call(__MODULE__, :discovered)
  end

  @doc """
  Terminates Sonex.Discovery GenServer
  """
  def kill() do
    GenServer.stop(__MODULE__, "Done")
  end

  def handle_info({:discovered, _new_device}, state), do: {:noreply, state}
  def handle_info({:start, _new_device}, state), do: {:noreply, state}

  def handle_info(
        {:updated, %SonosDevice{uuid: new_uuid} = new_device},
        %{players: players} = state
      ) do
    players =
      players
      |> Enum.map(fn p ->
        if get_uuid(p) == new_uuid,
          do: new_device |> IO.inspect(label: "did replace dev"),
          else: p
      end)

    {:noreply, %{state | players: players}}
  end

  def handle_info({:udp, _socket, ip, _fromport, packet}, state) do
    with this_player <- parse_upnp(ip, packet),
         {name, icon, config} <- attributes(this_player),
         {:bridge, true} <- {:bridge, name != "BRIDGE"},
         {_, zone_coordinator, _} = group_attributes(this_player) do
      player = %SonosDevice{
        this_player
        | name: name,
          icon: icon,
          config: config,
          coordinator_uuid: zone_coordinator
      }

      State.put_device(player)
    else
      {:bridge, true} ->
        Logger.debug("found bridge")

      e ->
        IO.inspect(e, label: "the errors")
    end

    {:noreply, state}
  end

  def handle_cast(:kill, state) do
    :ok = :gen_udp.close(state.socket)
    {:noreply, state}
  end

  def handle_cast(:discover, state) do
    :gen_udp.send(state.socket, @multicastaddr, @multicastport, @playersearch)
    {:noreply, state}
  end

  def handle_info(:initialize_network, state) do
    IO.inspect(state, label: "handing initialize_network")
    state = attempt_network_init(state)
    {:noreply, state}
  end

  defp attempt_network_init(state) do
    case get_ip() do
      {:ok, nil} ->
        Process.send_after(self(), :initialize_network, @polling_duration)
        %DiscoverState{state | state: :disconnected}

      {:ok, ip_addr} ->
        {:ok, socket} =
          :gen_udp.open(0, [
            :binary,
            :inet,
            {:ip, ip_addr},
            {:active, true},
            {:multicast_if, ip_addr},
            {:multicast_ttl, 4},
            {:add_membership, {@multicastaddr, ip_addr}}
          ])

        # fire two udp discover packets immediately
        :gen_udp.send(socket, @multicastaddr, @multicastport, @playersearch)
        :gen_udp.send(socket, @multicastaddr, @multicastport, @playersearch)
        %DiscoverState{state | socket: socket, state: :connected}
    end
  end

  defp attributes(%SonosDevice{} = player) do
    import SweetXml
    {:ok, res_body} = Sonex.SOAP.build(:device, "GetZoneAttributes") |> Sonex.SOAP.post(player)

    {xpath(res_body, ~x"//u:GetZoneAttributesResponse/CurrentZoneName/text()"s),
     xpath(res_body, ~x"//u:GetZoneAttributesResponse/CurrentIcon/text()"s),
     xpath(res_body, ~x"//u:GetZoneAttributesResponse/CurrentConfiguration/text()"i)}
  end

  defp group_attributes(%SonosDevice{} = player) do
    import SweetXml
    {:ok, res_body} = Sonex.SOAP.build(:zone, "GetZoneGroupAttributes") |> Sonex.SOAP.post(player)

    {zone_name, zone_id, player_list} =
      {xpath(res_body, ~x"//u:GetZoneGroupAttributesResponse/CurrentZoneGroupName/text()"s),
       xpath(res_body, ~x"//u:GetZoneGroupAttributesResponse/CurrentZoneGroupID/text()"s),
       xpath(
         res_body,
         ~x"//u:GetZoneGroupAttributesResponse/CurrentZonePlayerUUIDsInGroup/text()"ls
       )}

    clean_zone =
      case String.split(zone_id, ":") do
        [one, _] ->
          one

        [""] ->
          ""
      end

    case(zone_name) do
      "" ->
        {nil, clean_zone, player_list}

      _ ->
        {zone_name, clean_zone, player_list}
    end
  end

  def zone_group_state(%SonosDevice{} = player) do
    import SweetXml

    {:ok, res} =
      Sonex.SOAP.build(:zone, "GetZoneGroupState", [])
      |> Sonex.SOAP.post(player)

    xpath(res, ~x"//ZoneGroupState/text()"s)
    |> xpath(~x"//ZoneGroups/ZoneGroup"l,
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
  end

  defp parse_upnp(ip, good_resp) do
    split_resp = String.split(good_resp, "\r\n")
    vers_model = Enum.fetch!(split_resp, 4)

    if String.contains?(vers_model, "Sonos") do
      ["SERVER:", "Linux", "UPnP/1.0", version, model_raw] = String.split(vers_model)
      model = String.trim(model_raw)
      "USN: uuid:" <> usn = Enum.fetch!(split_resp, 6)
      uuid = String.split(usn, "::") |> Enum.at(0)
      "X-RINCON-HOUSEHOLD: " <> household = Enum.fetch!(split_resp, 7)

      %SonosDevice{
        ip: format_ip(ip),
        version: version,
        model: model,
        uuid: uuid,
        household: household
      }
    end
  end

  defp get_uuid(%SonosDevice{uuid: new_uuid}), do: new_uuid

  def get_ip do
    dev_name = Application.get_env(:sonex, Sonex.Discovery)[:net_device_name]

    en0 = to_charlist(dev_name)
    {:ok, test_socket} = :inet_udp.open(8989, [])

    ip_addr =
      case :inet.ifget(test_socket, en0, [:addr]) do
        {:ok, [addr: ip]} ->
          ip

        {:ok, []} ->
          case :prim_inet.ifget(test_socket, en0, [:addr]) do
            {:ok, [addr: ip]} ->
              ip

            {:ok, []} ->
              nil
          end
      end

    :inet_udp.close(test_socket)
    {:ok, ip_addr}
  end

  defp format_ip({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end
end
