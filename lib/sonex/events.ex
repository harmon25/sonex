defmodule Sonex.DefaultHandler do
  use GenEvent
  require Logger

  def init(_args) do 
    Logger.info("Event handler added!")
    {:ok, _args}
  end

   def handle_event({:test, msg}, _state) do
    Logger.info("test event received: #{msg}")
    {:ok, _state}
  end

  def handle_event({:discovered, %SonosDevice{} = new_device}, _state) do
    Logger.info("discovered device! #{inspect new_device}")
    #is this device a coordinator?
    case(new_device.uuid == new_device.coordinator_uuid) do
      true  -> 
        Logger.info("this is a coordinator! #{new_device.name} sub to more things")
        Sonex.SubMngr.subscribe(new_device, Sonex.Service.get(:av))
        Sonex.SubMngr.subscribe(new_device, Sonex.Service.get(:renderer))
      false ->
        Logger.info("This is just a player #{new_device.name}")
        Sonex.SubMngr.subscribe(new_device, Sonex.Service.get(:renderer))
    end
    {:ok, _state}
  end

end


defmodule Sonex.EventMngr do

 def start_link() do
  {:ok, pid } = GenEvent.start_link(name: __MODULE__)
  GenEvent.add_handler(__MODULE__, Sonex.DefaultHandler, [])
  {:ok, pid }
 end

 def add_handler(handler) do
    GenEvent.add_handler(__MODULE__, handler, [])
 end

end