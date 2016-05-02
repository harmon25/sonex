#defmodule SonosDevice do
#  defstruct  ip: nil, model: nil, uuid: nil, household: nil, name: nil, config: nil, icon: nil, version: nil, coordinator_uuid: nil, coordinator_pid: nil
#  @type t :: %__MODULE__{ip: String.t, model: String.t, uuid: String.t, household: String.t, name: String.t, config: integer, icon: String.t, version: String.t, coordinator_uuid: String.t, coordinator_pid: reference }
#end

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

  def start_link(%ZonePlayer{} = empty_state) do
    GenServer.start_link(__MODULE__, empty_state, name: ref(empty_state.id))
  end
  
  def init(%ZonePlayer{} = player) do
    GenEvent.notify(Sonex.EventMngr, {:discovered, player})
    {:ok, player}
  end


  # ...

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
