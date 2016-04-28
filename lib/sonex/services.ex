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

  defp make_control_rendered(service) do
     "/MediaRenderer/#{service}/Control"
  end

  defp make_event_rendered(service) do
     "/MediaRenderer/#{service}/Event"
  end

  defp make_event(service) do
     "/#{service}/Event"
  end

  defp make_url(service) do
     "/xml/#{service}1.xml"
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:AudioIn:1</serviceType>
  <controlURL>/AudioIn/Control</controlURL>
  <eventSubURL>/AudioIn/Event</eventSubURL>
  <SCPDURL>/xml/AudioIn1.xml</SCPDURL>
  """
  def get(:audio_in) do
    %{ type: make_type(@audio_input), 
       control: make_control(@audio_input),
       event: make_event(@audio_input),
       scpd_url: make_url(@audio_input)
     }
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:AlarmClock:1</serviceType>
  <controlURL>/AlarmClock/Control</controlURL>
  <eventSubURL>/AlarmClock/Event</eventSubURL>
  <SCPDURL>/xml/AlarmClock1.xml</SCPDURL>
  """
  def get(:alarm) do
    %{ type: make_type(@alarm_clock), 
       control: make_control(@alarm_clock),
       event: make_event(@alarm_clock),
       scpd_url: make_url(@alarm_clock)
     }
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
  <controlURL>/MediaRenderer/AVTransport/Control</controlURL>
  <eventSubURL>/MediaRenderer/AVTransport/Event</eventSubURL>
  <SCPDURL>/xml/AVTransport1.xml</SCPDURL>
  """
  def get(:av) do
    %{ type: make_type(@av_transport), 
       control: make_control_rendered(@av_transport),
       event: make_event_rendered(@av_transport),
       scpd_url: make_url(@av_transport)
     }
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
  <controlURL>/MediaRenderer/RenderingControl/Control</controlURL>
  <eventSubURL>/MediaRenderer/RenderingControl/Event</eventSubURL>
  <SCPDURL>/xml/RenderingControl1.xml</SCPDURL>
  """
  def get(:rendered) do
    %{ type: make_type(@redering_cont), 
       control: make_control_rendered( @redering_cont),
       event: make_event_rendered( @redering_cont),
       scpd_url: make_url(@redering_cont)
     }
  end

  @doc """
  <serviceType>urn:schemas-sonos-com:service:Queue:1</serviceType>
  <controlURL>/MediaRenderer/Queue/Control</controlURL>
  <eventSubURL>/MediaRenderer/Queue/Event</eventSubURL>
  <SCPDURL>/xml/Queue1.xml</SCPDURL>
  """
  def get(:queue) do
    %{ type: make_type(@aq), 
       control: make_control_rendered(@q),
       event: make_event_rendered(@q),
       scpd_url: make_url(@q)
     }
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:DeviceProperties:1</serviceType>
    <controlURL>/DeviceProperties/Control</controlURL>
    <eventSubURL>/DeviceProperties/Event</eventSubURL>
    <SCPDURL>/xml/DeviceProperties1.xml</SCPDURL>
  """
  def get(:device) do
    %{ type: make_type(@device_props), 
       control: make_control(@device_props),
       event: make_event(@device_props),
       scpd_url: make_url(@device_props)
     }
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:MusicServices:1</serviceType>
    <controlURL>/MusicServices/Control</controlURL>
    <eventSubURL>/MusicServices/Event</eventSubURL>
    <SCPDURL>/xml/MusicServices1.xml</SCPDURL>
  """
  def get(:music) do
    %{ type: make_type(@music_services), 
       control: make_control(@music_services),
       event: make_event(@music_services),
       scpd_url: make_url(@music_services)
     }
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:ZoneGroupTopology:1</serviceType>
  <controlURL>/ZoneGroupTopology/Control</controlURL>
  <eventSubURL>/ZoneGroupTopology/Event</eventSubURL>
  <SCPDURL>/xml/ZoneGroupTopology1.xml</SCPDURL>
  """
  def get(:zone) do
    %{ type: make_type(@zone_group), 
       control: make_control(@zone_group),
       event: make_event(@zone_group),
       scpd_url: make_url(@zone_group)
     }
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:SystemProperties:1</serviceType>
  <controlURL>/SystemProperties/Control</controlURL>
  <eventSubURL>/SystemProperties/Event</eventSubURL>
  <SCPDURL>/xml/SystemProperties1.xml</SCPDURL>
  """
  def get(:system) do
    %{ type: make_type(@system_props), 
       control: make_control(@system_props),
       event: make_event(@system_props),
       scpd_url: make_url(@system_props)
     }
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:GroupManagement:1</serviceType>
    <controlURL>/GroupManagement/Control</controlURL>
    <eventSubURL>/GroupManagement/Event</eventSubURL>
    <SCPDURL>/xml/GroupManagement1.xml</SCPDURL>
  """
  def get(:group) do
    %{ type: make_type(@group_mgmt), 
       control: make_control(@group_mgmt),
       event: make_event(@group_mgmt),
       scpd_url: make_url(@group_mgmt)
     }
  end

  @doc """
    <serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType>
    <controlURL>/MediaServer/ContentDirectory/Control</controlURL>
    <eventSubURL>/MediaServer/ContentDirectory/Event</eventSubURL>
    <SCPDURL>/xml/ContentDirectory1.xml</SCPDURL>
  """
  def get(:content) do
    %{ type: make_type(@content_dir), 
       control: make_control_server(@content_dir),
       event: make_event_server(@content_dir),
       scpd_url: make_url(@content_dir)
     }
  end

  @doc """
  <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
  <controlURL>/MediaServer/ConnectionManager/Control</controlURL>
  <eventSubURL>/MediaServer/ConnectionManager/Event</eventSubURL>
  <SCPDURL>/xml/ConnectionManager1.xml</SCPDURL>
  """
  def get(:conn) do
    %{ type: make_type( @conn_mngr), 
       control: make_control_server(@conn_mngr),
       event: make_event_server(@conn_mngr),
       scpd_url: make_url(@conn_mngr)
     }
  end

  def actions(service) do

    case(Sonex.Discovery.discovered?) do
      true ->
          serv = get(service)
          {:ok, players } = Sonex.Discovery.players
          player = hd(players)
          %HTTPoison.Response{status_code: 200, body: res_body, headers: _resp_headers} = 
          HTTPoison.get!("http://" <> player.ip <> ":1400" <> serv.scpd_url)
          IO.puts res_body
      false ->
        {:error, "no devices to query for actions"}
    end
     #
     #
  end

end
