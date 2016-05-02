defmodule Sonex.SubHelpers do

  def create_sub_data(request, type) do
    {:undefined, "uuid:" <> uuid_raw, _ } = :cowboy_req.parse_header(<<"sid">>, request)
    {:undefined, seq, _ } = :cowboy_req.parse_header(<<"seq">>, request)
    [header, main, _sub_id ] = String.split(uuid_raw, "_")
    from_id = header <> "_" <> main
    %SubData{from: from_id, seq_num: seq, sub_id: uuid_raw, type: type}
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
