defmodule SonosDevice do
  defstruct ip: nil,
            model: nil,
            uuid: nil,
            household: nil,
            name: nil,
            config: nil,
            icon: nil,
            version: nil,
            coordinator_uuid: nil,
            coordinator_pid: nil,
            info: nil,
            player_state: %PlayerState{}

  @type t :: %__MODULE__{
          ip: String.t(),
          model: String.t(),
          uuid: String.t(),
          household: String.t(),
          name: String.t(),
          config: integer,
          icon: String.t(),
          version: String.t(),
          coordinator_uuid: String.t(),
          coordinator_pid: reference,
          info: String.t(),
          player_state: PlayerState.t()
        }
end
