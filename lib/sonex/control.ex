defmodule Sonex.Control do
  def setName(%SonosDevice{} = device, new_name ) do
    resp = Sonex.SOAP.build(:device, "SetZoneAttributes", [ ["DesiredZoneName", new_name],
                                                     ["DesiredIcon", device.icon],
                                                     ["DesiredConfiguration", device.config]
                                                   ] )
    |> Sonex.SOAP.post(device.ip)

     case(resp) do
      %HTTPoison.Response{status_code: 200} ->
          # name was set, discover new name.
          Sonex.Discovery.discover()
      _ ->
         IO.puts "bad resp!"

     end

  end
end