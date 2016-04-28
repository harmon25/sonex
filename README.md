# Sonex
Elixir Sonos Controller Elixir "Application"

- Allows for basic control of Sonos household from Elixir/Erlang 
- Discovers Sonos Devices on LAN once application is launched

## Example
```
alias Sonex.Discovery
alias Sonex.Player
den_player = Sonex.Discovery.playerByName("Den")
portable = Sonex.Discovery.playerByName("Portable")
den_player |> Sonex.Discovery.zone_group_state()
portable |> Player.zone_group_state()
portable |> Player.group(:leave)
portable |> Player.control(:pause)
portable |> Player.audio(:volume)
portable |> Player.audio(:volume, 50)
den_player |> Player.control(:pause)
den_player |> Player.position_info()

```

## Installation

On Linux
`sudo apt-get install erlang-xmerl`

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add sonex to your list of dependencies in `mix.exs`:

        def deps do
          [{:sonex, "~> 0.0.1"}]
        end

  2. Ensure sonex is started before your application:

        def application do
          [applications: [:sonex]]
        end
