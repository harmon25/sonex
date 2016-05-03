defmodule Sonex.PlayerMonitor do
  use GenServer

  def create(%ZonePlayer{} = empty_state) do
    case GenServer.whereis(ref(empty_state.id)) do
      nil ->
        Supervisor.start_child(Sonex.Player.Supervisor, [empty_state])
      _zone ->
        {:error, :player_already_exists}
    end
  end


  def player_by_name(name) do
    player = Enum.flat_map(Sonex.Discovery.players(), fn(player) -> [GenServer.whereis({:global,{:player, player.uuid}})] end)
    |> Enum.filter(fn(pid) -> name == GenServer.call(pid, {:name}) end)
    case(player) do
      [zone_player] ->
        {:ok, zone_player}
       [] ->
         {:error, "Player of that name does not exist"}
     end
  end

  def player_by_name!(name) do
    player = Enum.flat_map(Sonex.Discovery.players(), fn(player) -> [GenServer.whereis({:global,{:player, player.uuid}})] end)
    |> Enum.filter(fn(pid) -> name == GenServer.call(pid, {:name}) end)
    case(player) do
      [zone_player] ->
         zone_player
       [] ->
         :error
     end
  end

  def player_details(name) do
    case(player_by_name!(name)) do
      :error -> "Player does not exist"
      player -> GenServer.call(player, {:details})
    end
  end


  def start_link(%ZonePlayer{} = empty_state) do
    GenServer.start_link(__MODULE__, empty_state, name: ref(empty_state.id))
  end

  def init(%ZonePlayer{} = player) do
    # triggers subscription
    GenEvent.notify(Sonex.EventMngr, {:discovered, player})
    {:ok, player}
  end


  # ...

  def handle_cast({ :set_name, name }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | name: name} }
  end

  def handle_cast({ :set_coordinator, coordinator }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | coordinator_id: coordinator} }
  end

  def handle_cast({ :set_volume, volume_map }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | player_state: %PlayerState{player.player_state | volume: volume_map }} }
  end

  def handle_cast({ :set_mute, mute }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | player_state: %PlayerState{player.player_state | mute: mute }} }
  end

  def handle_cast({ :set_treble, treble }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | player_state: %PlayerState{player.player_state | treble: treble }} }
  end

  def handle_cast({ :set_bass, bass }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | player_state: %PlayerState{player.player_state | bass: bass }} }
  end

  def handle_cast({ :set_loudness, loudness }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | player_state: %PlayerState{player.player_state | loudness: loudness }} }
  end

  def handle_cast({ :set_state, new_player_state }, %ZonePlayer{} = player) do
      { :noreply, %ZonePlayer{player | player_state: %PlayerState{player.player_state |
      current_state: new_player_state.current_state,
      current_mode:  new_player_state.mode,
      total_tracks: new_player_state.tracks_total,
      track_number: new_player_state.current_track,
      track_info: new_player_state.track_info
       }} }
  end




  def handle_call({ :name }, _from, %ZonePlayer{} = player) do
    { :reply, player.name, player }
  end

  def handle_call({ :details }, _from, %ZonePlayer{} = player) do
    { :reply, player, player }
  end

  defp ref(player_id) do
    {:global, {:player, player_id}}
  end


  defp try_call(player_id, message) do
    case GenServer.whereis(ref(player_id)) do
      nil ->
        {:error, :invalid_player}
      player ->
        GenServer.call(player, message)
    end
  end
end
