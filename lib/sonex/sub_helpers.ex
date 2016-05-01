defmodule SubData do
    defstruct  type: nil, sub_id: nil, from: nil, seq_num: nil, content: nil
    @type t :: %__MODULE__{type: String.t, sub_id: String.t, from: String.t, seq_num: integer, content: map}
end


defmodule Sonex.SubHelpers do

  def create_sub_data(request, type) do
    {:undefined, "uuid:" <> uuid_raw, _ } = :cowboy_req.parse_header(<<"sid">>, request)
    {:undefined, seq, _ } = :cowboy_req.parse_header(<<"seq">>, request)
    [header, main, sub_id ] = String.split(uuid_raw, "_")
    uuid = header <> "_" <> main
    %SubData{from: uuid, seq_num: seq, sub_id: sub_id, type: type}
  end

  def clean_xml_str(xml) do
    cleaned_xml =
    xml
    |> clean_resp("&lt;", "<")
    |> clean_resp("&gt;", ">")
    |> clean_resp("&quot;", "\"")
  end

  def clean_resp(resp, to_clean, replace_with) do
     String.replace(resp, to_clean, replace_with)
  end

end
