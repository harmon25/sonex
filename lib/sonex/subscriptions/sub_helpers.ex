defmodule Sonex.SubHelpers do
  def create_sub_data(%{headers: %{"sid" => sid, "seq" => seq}} = _request, type) do
    "uuid:" <> uuid_raw = sid
    [header, main, _sub_id] = String.split(uuid_raw, "_")
    from_id = header <> "_" <> main
    %SubscriptionEvent{from: from_id, seq_num: seq, sub_id: uuid_raw, type: type}
  end

  def create_sub_data(request, _type) do
    IO.inspect(request, label: "requestrequestrequestrequestrequest")
  end

  def clean_xml_str(xml) do
    _cleaned_xml =
      xml
      |> clean_resp("&lt;", "<")
      |> clean_resp("&gt;", ">")
      |> clean_resp("&quot;", "\"")
  end

  def clean_resp(resp, to_clean, replace_with) do
    String.replace(resp, to_clean, replace_with)
  end
end
