defmodule Sonex.Player do
  require Logger
  import SweetXml

  def setName(%SonosDevice{} = device, new_name ) do
    {:ok, _ } = Sonex.SOAP.build(:device, "SetZoneAttributes", [ ["DesiredZoneName", new_name],
                                                     ["DesiredIcon", device.icon],
                                                     ["DesiredConfiguration", device.config]
                                                   ] )
    |> Sonex.SOAP.post(device)
    |> refresh_zones()
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

    Sonex.SOAP.build(:av, act_str, [["InstanceID", 0], ["Speed", 1]])
    |> Sonex.SOAP.post(device)
    
  end

  def transport_info(%SonosDevice{} = device) do
    Sonex.SOAP.build(:av, "GetTransportInfo", [["InstanceID", 0]])
    |> Sonex.SOAP.post(device)
  end

  def position_info(%SonosDevice{} = device) do
    Sonex.SOAP.build(:av, "GetPositionInfo", [["InstanceID", 0]])
    |> Sonex.SOAP.post(device)
  end

  def group(%SonosDevice{} = device, :leave) do
     Sonex.SOAP.build(:av, "BecomeCoordinatorOfStandaloneGroup", [["InstanceID", 0]])
     |> Sonex.SOAP.post(device)
     |> refresh_zones()
  end

  def group(%SonosDevice{} = device, :join, coordinator_name) do
     coordinator = Sonex.Discovery.playerByName(coordinator_name)
     args = [["InstanceID", 0], ["CurrentURI", "x-rincon:" <> coordinator.usnID], ["CurrentURIMetaData", ""]]
     
     Sonex.SOAP.build(:av, "SetAVTransportURI", args )
     |> Sonex.SOAP.post(device)
     |> refresh_zones()
  end

  def audio(%SonosDevice{} = device, :volume, level) when level > 0 and level < 100 do
     args = [["InstanceID", 0], ["Channel", "Master"], ["DesiredVolume", level]]
     Sonex.SOAP.build(:rendered, "SetVolume", args )
     |> Sonex.SOAP.post(device)
  end

  def audio(%SonosDevice{} = device, :volume) do
    args = [["InstanceID", 0], ["Channel", "Master"]]
     Sonex.SOAP.build(:rendered, "GetVolume", args )
     |> Sonex.SOAP.post(device)
  end


  defp refresh_zones({:ok, response_body}) do
      Sonex.Discovery.discover()
      {:ok, response_body}
  end

  defp refresh_zones({:error, err_msg}) do
      {:error, err_msg}
  end


end