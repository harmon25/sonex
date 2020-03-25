# not using this, getting enough from zone sub
defmodule Sonex.SubHandlerDevice do
  #  import SweetXml
  alias Sonex.SubHelpers

  def init(req, _opts) do
    req |> IO.inspect(label: "device req")
    handle(req, %{})

    {:ok, req, :no_state}
  end

  def handle(request, state) do
    {:ok, data, _} = :cowboy_req.read_body(request, %{})

    sub_info_base = SubHelpers.create_sub_data(request, :device)

    clean_xml = SubHelpers.clean_xml_str(data)

    #  event_xml = xpath(clean_xml, ~x"//e:propertyset/e:property/LastChange/*[1]"e)
    # volume_state = xpath(event_xml, ~x"//Event/InstanceID/Volume/@val"il)
    # mute_info = xpath(event_xml, ~x"//Event/InstanceID/Mute/@val"il)
    #  sub_info = %SubscriptionEvent{sub_info_base | content: sub_content_map}

    IO.inspect(sub_info_base)

    {:ok, reply} = :cowboy_req.reply(200, request)

    # handle/2 returns a tuple starting containing :ok, the reply, and the
    # current state of the handler.
    {:ok, reply, state}
  end

  # Termination handler.  Usually you don't do much with this.  If things are breaking,
  # try uncommenting the output lines here to get some more info on what's happening.
  def terminate(_reason, _request, _state) do
    #    IO.puts("Terminating for reason: #{inspect(reason)}")
    #    IO.puts("Terminating after request: #{inspect(request)}")
    #    IO.puts("Terminating with state: #{inspect(state)}")
    :ok
  end
end
