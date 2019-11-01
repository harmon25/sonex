defmodule Sonex.Player do
  require Logger
  alias Sonex.SOAP
  alias Sonex.Network.State

  def setName(%SonosDevice{} = device, new_name) do
    {:ok, _} =
      SOAP.build(:device, "SetZoneAttributes", [
        ["DesiredZoneName", new_name],
        ["DesiredIcon", device.icon],
        ["DesiredConfiguration", device.config]
      ])
      |> SOAP.post(device)
  end

  def control(%SonosDevice{} = device, action) do
    act_str =
      case(action) do
        :play -> "Play"
        :pause -> "Pause"
        :stop -> "Stop"
        :prev -> "Previous"
        :next -> "Next"
      end

    SOAP.build(:av, act_str, [["InstanceID", 0], ["Speed", 1]])
    |> SOAP.post(device)
  end

  def transport_info(%SonosDevice{} = device) do
    SOAP.build(:av, "GetTransportInfo", [["InstanceID", 0]])
    |> SOAP.post(device)
  end

  def position_info(%SonosDevice{} = device) do
    SOAP.build(:av, "GetPositionInfo", [["InstanceID", 0]])
    |> SOAP.post(device)
  end

  def group(%SonosDevice{} = device, :leave) do
    SOAP.build(:av, "BecomeCoordinatorOfStandaloneGroup", [["InstanceID", 0]])
    |> SOAP.post(device)
  end

  def group(%SonosDevice{} = device, :join, coordinator_name) do
    coordinator = State.get_player(name: coordinator_name)

    args = [
      ["InstanceID", 0],
      ["CurrentURI", "x-rincon:" <> coordinator.usnID],
      ["CurrentURIMetaData", ""]
    ]

    SOAP.build(:av, "SetAVTransportURI", args)
    |> SOAP.post(device)
  end

  def audio(%SonosDevice{} = device, :volume, level) when level > 0 and level < 100 do
    args = [["InstanceID", 0], ["Channel", "Master"], ["DesiredVolume", level]]

    SOAP.build(:renderer, "SetVolume", args)
    |> SOAP.post(device)
  end

  def audio(%SonosDevice{} = device, :volume) do
    args = [["InstanceID", 0], ["Channel", "Master"]]

    SOAP.build(:renderer, "GetVolume", args)
    |> SOAP.post(device)
  end
end
