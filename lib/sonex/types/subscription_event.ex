defmodule SubscriptionEvent do
  defstruct type: nil, sub_id: nil, from: nil, seq_num: nil, content: nil

  @type t :: %__MODULE__{
          type: String.t(),
          sub_id: String.t(),
          from: String.t(),
          seq_num: integer,
          content: map
        }
end
