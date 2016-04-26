defmodule SOAPReq do
  defstruct  path: nil, method: nil , namespace: nil, header: nil, params: []
  @type t :: %__MODULE__{path: String.t, method: String.t, namespace: String.t, header: String.t, params: list(list)}
end


defmodule Sonex.SOAP do
  import SweetXml
  require EEx
  EEx.function_from_file(:def, :gen, Path.expand("./lib/sonex/request.xml.eex"), [:soap_req_struct])


  def build(service_atom, method, params \\ [], event \\ false) do
    serv = Sonex.Service.get(service_atom)
    req_path =
    case(event) do
      false -> serv.control
      true -> serv.event
    end
    %SOAPReq{method: method, namespace: serv.type, path: req_path , params: params}
  end

  def post(%SOAPReq{} = req_method, %SonosDevice{} = player) do
      req_headers = gen_headers(req_method)
      req_body = gen(req_method)
      uri = "http://#{player.ip}:1400#{req_method.path}"
      res = HTTPoison.post! uri, req_body, req_headers
      case(res) do
        %HTTPoison.Response{status_code: 200, body: res_body} ->
          {:ok, res_body}
        %HTTPoison.Response{status_code: 500, body: res_err} -> 
          {:error, parse_code(xpath(res_err,~x"//UPnPError/errorCode/text()"s))}
      end
  end

  defp parse_code(err_code) do
    case(err_code) do
     "400" -> "Bad Request"
     "401" -> "Invalid Action"
     "402" -> "Invalid Args"
     "404" -> "Invalid Var"
     "412" -> "Precondition Failed"
     "501" -> "Action Failed"
     "600" -> "Argument Value Invalid"
     "601" -> "Argument Value Out of Range"
     "602" -> "Optional Action Not Implemented"
     "603" -> "Out Of Memory"
     "604" -> "Human Intervention Required"
     "605" -> "String Argument Too Long"
     "606" -> "Action Not Authorized"
     "607" -> "Signature Failure"
     "608" -> "Signature Missing"
     "609" -> "Not Encrypted"
     "610" -> "Invalid Sequence"
     "611" -> "Invalid Control URL"
     "612" -> "No Such Session"
      _ -> "Unknown Error"
    end
  end

  def parse_resp() do
   xml = "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body><u:GetZoneAttributesResponse xmlns:u=\"urn:schemas-upnp-org:service:DeviceProperties:1\"><CurrentZoneName>Dining Room</CurrentZoneName><CurrentIcon>x-rincon-roomicon:dining</CurrentIcon><CurrentConfiguration>1</CurrentConfiguration></u:GetZoneAttributesResponse></s:Body></s:Envelope>"
   res = xml |> xpath(~x"//u:GetZoneAttributesResponse/CurrentZoneName/text()"s)
   IO.inspect res
  end

  defp gen_headers(soap_req) do
    %{"Content-Type"=>"text/xml; charset=\"utf-8\"" , "SOAPACTION"=>"\"#{soap_req.namespace}##{soap_req.method}\""}
  end

end