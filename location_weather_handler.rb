require 'nokogiri'
require 'open-uri'
require './flight_common'
require './sms_command_handler'

class LocationWeatherHandler < SmsCommandHandler
  def can_handle?(sms_text)
    command_pieces = sms_text.split(' ')
    command_pieces.count == 2 && command_pieces[1] == 'weather'
  end

  def failure_message
    'Cannot find weather information for this location.'
  end

  def handle(sms_text)
    location_id, _ = sms_text.split(' ')
    return 'Invalid location id.' unless is_valid_location_id?(location_id)
    location_weather(location_id)
  end

  private

  # This function may need to change according to the web structure changes in the scraped website.
  def extract_location_weather(url)
    page = Nokogiri::HTML(open(url))

    # We are aiming at find detail string in a structure like:
    # <html>
    #    ...
    #    <td>METAR text:</td>
    #    <td ...>
    #        KVGT 080253Z 26005KT 10SM CLR 27/00 A2983 RMK AO2 SLP098 T02670000 56000
    #    ...

    metar_tds = page.css('td').select { |node| node.text.strip == 'METAR text:' }
    return nil unless metar_tds.count > 0
    metar_td = metar_tds[0]

    metar_td.next_element.text.strip.split("\n").map(&:strip).join(' ')
  end

  def location_weather(location_id)
    extract_location_weather("http://www.aviationweather.gov/adds/metars/index?submit=1&station_ids=#{location_id}&chk_metars=on&hoursStr=8&std_trans=translated")
  end
end
