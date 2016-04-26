defmodule Sonex.Control do
  require Logger

  def setName(%SonosDevice{} = device, new_name ) do
    resp = Sonex.SOAP.build(:device, "SetZoneAttributes", [ ["DesiredZoneName", new_name],
                                                     ["DesiredIcon", device.icon],
                                                     ["DesiredConfiguration", device.config]
                                                   ] )
    |> Sonex.SOAP.post(device)

     case(resp) do
      {:ok, _res_body} ->
        # name was set, discover new name.
        Sonex.Discovery.discover()
      {:error, err_msg} ->
         Logger.error(err_msg)
     end
  end
end