defmodule Sonex do
  alias Sonex.Player
  alias Sonex.Network.State

  def get_zones() do
    State.zones()
  end

  def get_players() do
    State.players()
  end

  def get_player(uuid) do
    State.get_player(uuid)
  end

  def players_in_zone(zone_uuid) do
    State.players_in_zone(zone_uuid)
  end

  def start_player(player) do
    Player.control(player, :play)
  end

  def stop_player(player) do
    Player.control(player, :stop)
  end

  def set_volume(player, level) when is_binary(level) do
    Player.audio(player, :volume, String.to_integer(level))
  end

  def set_volume(player, level) do
    Player.audio(player, :volume, level)
  end
end
