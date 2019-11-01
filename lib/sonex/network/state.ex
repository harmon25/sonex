defmodule Sonex.Network.State do
  defmodule NetState do
    defstruct current_zone: "", players: %{}
  end

  use GenServer
  require Logger

  alias Sonex.Network.State.NetState

  def start_link(_vars) do
    GenServer.start_link(__MODULE__, %NetState{}, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def players do
    %{players: players} = get_state()
    Map.values(players)
  end

  def put_device(%SonosDevice{} = device) do
    GenServer.call(__MODULE__, {:update_device, device})
  end

  def players_in_zone(zone_uuid) do
    players()
    |> Enum.filter(fn p -> p.coordinator_uuid == zone_uuid end)
  end

  def zones() do
    players()
    |> Enum.filter(fn p -> p.coordinator_uuid == p.uuid end)
  end

  def get_player(uuid) do
    %{players: players} = get_state()
    Map.get(players, uuid)
  end

  def get_player_by_name(name) do
    players()
    |> Enum.find(nil, fn player ->
      player.name == name
    end)
  end

  def init(data) do
    {:ok, data}
  end

  def handle_call(:get_state, _from, %NetState{} = state) do
    {:reply, state, state}
  end

  def handle_call(
        {:update_device, %SonosDevice{uuid: uuid} = device},
        _from,
        %NetState{players: players} = state
      ) do
    players
    |> Map.get(uuid)
    |> case do
      nil ->
        Process.send(self(), {:broadcast, device, :discovered}, [])

      _dev ->
        Process.send(self(), {:broadcast, device, :updated}, [])
    end

    {:reply, :ok, %NetState{state | players: Map.put(players, uuid, device)}}
  end

  def terminate(reason, _state) do
    Logger.error("exiting Sonex.Network.State due to #{inspect(reason)}")
  end

  def handle_info({:broadcast, device, key}, state) do
    Registry.dispatch(Sonex, "devices", fn entries ->
      for {pid, _} <- entries do
        send(pid, {key, device})
      end
    end)

    {:noreply, state}
  end
end
