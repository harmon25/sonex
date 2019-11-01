defmodule Sonex.EventMngr do
  use GenServer
  require Logger

  def start_link(_vars) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(args) do
    {:ok, _} = Registry.register(Sonex, "devices", [])

    {:ok, args}
  end

  def handle_event({:test, msg}, state) do
    Logger.info("test event received: #{msg}")
    {:ok, state}
  end

  def handle_event({:execute, device}, state) do
    Logger.info("execute event received: #{inspect(device.name)}")

    {:ok, state}
  end

  def handle_info({:start, _new_device}, state), do: {:noreply, state}

  def handle_info({:updated, _new_device}, state), do: {:noreply, state}

  def handle_info({:discovered, new_device}, state) do
    Sonex.SubMngr.subscribe(new_device, Sonex.Service.get(:renderer))
    Sonex.SubMngr.subscribe(new_device, Sonex.Service.get(:zone))
    Sonex.SubMngr.subscribe(new_device, Sonex.Service.get(:av))
    # Sonex.SubMngr.subscribe(new_device, Sonex.Service.get(:device))

    {:noreply, state}
  end
end
