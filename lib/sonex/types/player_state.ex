defmodule PlayerState do
  @moduledoc """

  """

  defstruct volume: nil,
            mute: nil,
            bass: nil,
            treble: nil,
            loudness: nil,
            track_info: nil,
            track_number: nil,
            total_tracks: nil,
            current_state: nil,
            current_track: nil,
            current_mode: nil

  @type t :: %__MODULE__{
          volume: map,
          mute: boolean,
          bass: integer,
          treble: integer,
          loudness: boolean,
          track_info: map,
          track_number: integer,
          total_tracks: integer,
          current_state: String.t(),
          current_track: String.t(),
          current_mode: String.t()
        }
end
