defmodule Sonex.SOAP do
  require EEx
  import SweetXml

  @moduledoc """
  Functions for generating and sending Sonos SOAP requests via HTTP
  """

  defmodule SOAPReq do
    @moduledoc """
    Struct that represents the contents of a Sonos XML SOAP request
    Typically only requires method and params
    Build using build() function, it will automatically fill in namespace based on specific service
    """

    defstruct path: nil, method: nil, namespace: nil, header: nil, params: []

    @type t :: %__MODULE__{
            path: String.t(),
            method: String.t(),
            namespace: String.t(),
            header: String.t(),
            params: list(list)
          }
  end

  @doc """
  Generates a SOAP XML for the Sonos API based on SOAPReq Struct
  """
  EEx.function_from_file(:def, :gen, Path.expand("./lib/sonex/request.xml.eex"), [
    :soap_req_struct
  ])

  @doc """
  Build a SOAPReq Struct, to be passed to post function
  """
  def build(service_atom, method, params \\ [], event \\ false) do
    serv = Sonex.Service.get(service_atom)

    req_path =
      case(event) do
        false -> serv.control
        true -> serv.event
      end

    %SOAPReq{method: method, namespace: serv.type, path: req_path, params: params}
  end

  @doc """
  Generates XML request body and sends via HTTP post to specified %SonosDevice{}
  Returns response body as XML, or error based on codes
  """
  def post(%SOAPReq{} = req, %SonosDevice{} = player) do
    req_headers = gen_headers(req)
    req_body = gen(req)
    uri = "http://#{player.ip}:1400#{req.path}"
    res = HTTPoison.post!(uri, req_body, req_headers)

    case(res) do
      %HTTPoison.Response{status_code: 200, body: res_body} ->
        {:ok, res_body}

      %HTTPoison.Response{status_code: 500, body: res_err} ->
        case(req.namespace) do
          "urn:schemas-upnp-org:service:ContentDirectory:1" ->
            {:error, parse_soap_error(res_err, true)}

          _ ->
            {:error, parse_soap_error(res_err)}
        end
    end
  end

  defp gen_headers(soap_req) do
    %{
      "Content-Type" => "text/xml; charset=\"utf-8\"",
      "SOAPACTION" => "\"#{soap_req.namespace}##{soap_req.method}\""
    }
  end

  def parse_soap_error(err_body, content_dir_req \\ false) do
    # https://github.com/SoCo/SoCo/blob/master/soco/services.py
    # For error codes, see table 2.7.16 in
    # http://upnp.org/specs/av/UPnP-av-ContentDirectory-v1-Service.pdf
    # http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf
    case(xpath(err_body, ~x"//UPnPError/errorCode/text()"i)) do
      400 -> "Bad Request"
      401 -> "Invalid Action"
      402 -> "Invalid Args"
      404 -> "Invalid Var"
      412 -> "Precondition Failed"
      501 -> "Action Failed"
      600 -> "Argument Value Invalid"
      601 -> "Argument Value Out of Range"
      602 -> "Optional Action Not Implemented"
      603 -> "Out Of Memory"
      604 -> "Human Intervention Required"
      605 -> "String Argument Too Long"
      606 -> "Action Not Authorized"
      607 -> "Signature Failure"
      608 -> "Signature Missing"
      609 -> "Not Encrypted"
      610 -> "Invalid Sequence"
      611 -> "Invalid Control URL"
      612 -> "No Such Session"
      701 when content_dir_req == true -> "No such object"
      701 -> "Transition not available"
      702 when content_dir_req == true -> "Invalid CurrentTagValue"
      702 -> "No contents"
      703 when content_dir_req == true -> "Invalid NewTagValue"
      703 -> "Read error"
      704 when content_dir_req == true -> "Required tag"
      704 -> "Format not supported for playback"
      705 when content_dir_req == true -> "Read only tag"
      705 -> "Transport is locked"
      706 when content_dir_req == true -> "Parameter Mismatch"
      706 -> "Write error"
      707 -> "Media is protected or not writeable"
      708 when content_dir_req == true -> "Unsupported or invalid search criteria"
      708 -> "Format not supported for recording"
      709 when content_dir_req == true -> "Unsupported or invalid sort criteria"
      709 -> "Media is full"
      710 when content_dir_req == true -> "No such container"
      710 -> "Seek mode not supported"
      711 when content_dir_req == true -> "Restricted object"
      711 -> "Illegal seek target"
      712 when content_dir_req == true -> "Bad metadata"
      712 -> "Play mode not supported"
      713 when content_dir_req == true -> "Restricted parent object"
      713 -> "Record quality not supported"
      714 when content_dir_req == true -> "No such source resource"
      714 -> "Illegal MIME-Type"
      715 when content_dir_req == true -> "Resource access denied"
      715 -> "Content BUSY"
      716 when content_dir_req == true -> "Transfer busy"
      716 -> "Resource Not found"
      717 when content_dir_req == true -> "No such file transfer"
      717 -> "Play speed not supported"
      718 when content_dir_req == true -> "No such destination resource"
      718 -> "Invalid InstanceID"
      719 -> "Destination resource access denied"
      720 -> "Cannot process the request"
      737 -> "No DNS Server"
      738 -> "Bad Domain Name"
      739 -> "Server Error"
      _ -> "Unknown Error"
    end
  end
end
