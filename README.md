# Sonex

Elixir Sonos Controller

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add sonex to your list of dependencies in `mix.exs`:

        def deps do
          [{:sonex, "~> 0.0.1"}]
        end

  2. Ensure sonex is started before your application:

        def application do
          [applications: [:sonex]]
        end
