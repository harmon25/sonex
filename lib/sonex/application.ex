defmodule Sonex.Application do
  @moduledoc false

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Sonex},
      Sonex.Network.State,
      Sonex.EventMngr,
      worker(Sonex.Discovery, []),
      worker(Sonex.SubMngr, [])
    ]

    opts = [strategy: :one_for_one, name: LibAstroEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
