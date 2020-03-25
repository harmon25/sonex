defmodule Sonex.Service do
  @alarm_clock "AlarmClock"
  @audio_input "AudioIn"
  @device_props "DeviceProperties"
  @music_services "MusicServices"
  @system_props "SystemProperties"
  @redering_cont "RenderingControl"
  @zone_group "ZoneGroupTopology"
  @group_mgmt "GroupManagement"
  @content_dir "ContentDirectory"
  @conn_mngr "ConnectionManager"
  @av_transport "AVTransport"
  @q "Queue"

  @doc """
  <serviceType>urn:schemas-upnp-org:service:AudioIn:1</serviceType>
  <controlURL>/AudioIn/Control</controlURL>
  <eventSubURL>/AudioIn/Event</eventSubURL>
  <SCPDURL>/xml/AudioIn1.xml</SCPDURL>
  """
  def get(:audio_in) do
    make_service(@audio_input)
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:DeviceProperties:1</serviceType>
    <controlURL>/DeviceProperties/Control</controlURL>
    <eventSubURL>/DeviceProperties/Event</eventSubURL>
    <SCPDURL>/xml/DeviceProperties1.xml</SCPDURL>
  """
  def get(:device) do
    make_service(@device_props)
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:MusicServices:1</serviceType>
    <controlURL>/MusicServices/Control</controlURL>
    <eventSubURL>/MusicServices/Event</eventSubURL>
    <SCPDURL>/xml/MusicServices1.xml</SCPDURL>
  """
  def get(:music) do
    make_service(@music_services)
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:ZoneGroupTopology:1</serviceType>
  <controlURL>/ZoneGroupTopology/Control</controlURL>
  <eventSubURL>/ZoneGroupTopology/Event</eventSubURL>
  <SCPDURL>/xml/ZoneGroupTopology1.xml</SCPDURL>
  """
  def get(:zone) do
    make_service(@zone_group)
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:SystemProperties:1</serviceType>
  <controlURL>/SystemProperties/Control</controlURL>
  <eventSubURL>/SystemProperties/Event</eventSubURL>
  <SCPDURL>/xml/SystemProperties1.xml</SCPDURL>
  """
  def get(:system) do
    make_service(@system_props)
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:GroupManagement:1</serviceType>
    <controlURL>/GroupManagement/Control</controlURL>
    <eventSubURL>/GroupManagement/Event</eventSubURL>
    <SCPDURL>/xml/GroupManagement1.xml</SCPDURL>
  """
  def get(:group) do
    make_service(@group_mgmt)
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType>
    <controlURL>/MediaServer/ContentDirectory/Control</controlURL>
    <eventSubURL>/MediaServer/ContentDirectory/Event</eventSubURL>
    <SCPDURL>/xml/ContentDirectory1.xml</SCPDURL>
  """
  def get(:content) do
    make_service(@content_dir, :server)
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
  <controlURL>/MediaServer/ConnectionManager/Control</controlURL>
  <eventSubURL>/MediaServer/ConnectionManager/Event</eventSubURL>
  <SCPDURL>/xml/ConnectionManager1.xml</SCPDURL>
  """
  def get(:conn) do
    make_service(@conn_mngr, :server)
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:AlarmClock:1</serviceType>
  <controlURL>/AlarmClock/Control</controlURL>
  <eventSubURL>/AlarmClock/Event</eventSubURL>
  <SCPDURL>/xml/AlarmClock1.xml</SCPDURL>
  """
  def get(:alarm) do
    make_service(@alarm_clock, :renderer)
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
  <controlURL>/MediaRenderer/AVTransport/Control</controlURL>
  <eventSubURL>/MediaRenderer/AVTransport/Event</eventSubURL>
  <SCPDURL>/xml/AVTransport1.xml</SCPDURL>
  """
  def get(:av) do
    make_service(@av_transport, :renderer)
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
  <controlURL>/MediaRenderer/RenderingControl/Control</controlURL>
  <eventSubURL>/MediaRenderer/RenderingControl/Event</eventSubURL>
  <SCPDURL>/xml/RenderingControl1.xml</SCPDURL>
  """
  def get(:renderer) do
    make_service(@redering_cont, :renderer)
  end

  @doc """
  <serviceType>urn:schemas-sonos-com:service:Queue:1</serviceType>
  <controlURL>/MediaRenderer/Queue/Control</controlURL>
  <eventSubURL>/MediaRenderer/Queue/Event</eventSubURL>
  <SCPDURL>/xml/Queue1.xml</SCPDURL>
  """
  def get(:queue) do
    make_service(@q, :renderer)
  end

  def actions(service) do
    case(Enum.count(Sonex.get_players()) > 0) do
      true ->
        serv = get(service)
        {:ok, players} = Sonex.get_players()
        player = hd(players)

        %HTTPoison.Response{status_code: 200, body: res_body, headers: _resp_headers} =
          HTTPoison.get!("http://" <> player.ip <> ":1400" <> serv.scpd_url)

        IO.puts(res_body)

      false ->
        {:error, "no devices to query for actions"}
    end

    #
    #
  end

  defp make_service(service_name) do
    %{
      type: make_type(service_name),
      control: make_control(service_name),
      event: make_event(service_name),
      scpd_url: make_url(service_name)
    }
  end

  defp make_service(service_name, :renderer) do
    %{
      type: make_type(service_name),
      control: make_control_renderer(service_name),
      event: make_event_renderer(service_name),
      scpd_url: make_url(service_name)
    }
  end

  defp make_service(service_name, :server) do
    %{
      type: make_type(service_name),
      control: make_control_server(service_name),
      event: make_event_server(service_name),
      scpd_url: make_url(service_name)
    }
  end

  defp make_type(service) do
    "urn:schemas-upnp-org:service:#{service}:1"
  end

  defp make_control(service) do
    "/#{service}/Control"
  end

  defp make_control_server(service) do
    "/MediaServer/#{service}/Control"
  end

  defp make_event_server(service) do
    "/MediaServer/#{service}/Event"
  end

  defp make_control_renderer(service) do
    "/MediaRenderer/#{service}/Control"
  end

  defp make_event_renderer(service) do
    "/MediaRenderer/#{service}/Event"
  end

  defp make_event(service) do
    "/#{service}/Event"
  end

  defp make_url(service) do
    "/xml/#{service}1.xml"
  end
end
