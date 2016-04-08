require 'nokogiri'
require 'open-uri'
require './flight_common'
require './sms_command_handler'

class AircraftInfoHandler < SmsCommandHandler
  def can_handle?(sms_text)
    command_pieces = sms_text.split
    command_pieces.count == 2 && command_pieces[1] == 'info'
  end

  def failure_message
    'Cannot find information for this aircraft.'
  end

  def handle(sms_text)
    aircraft_id, = sms_text.split
    return 'Invalid aircraft id.' unless is_valid_aircraft_id?(aircraft_id)
    flight_info(aircraft_id)
  end

  private

  # This function may need to change according to the web structure changes in the scraped website.
  def extract_aircraft_info(url)
    page = Nokogiri::HTML(open(url))

    # We are aiming at find detail string in a structure like:
    # <html>
    #    ...
    #    <div ... >
    #       <legend>Aircraft Summary</legend>
    #       ...
    #          <div class='... title-text'>Summary</div>
    #          <div ...>
    #               "2005 PILATUS AIRCRAFT ..."
    #               ...
    #          </div>
    #          ...
    #       ...

    summary_legends = page.css('legend').select { |node| node.text == 'Aircraft Summary' }
    return nil unless summary_legends.count > 0
    summary_legend = summary_legends[0]

    summary_titles = summary_legend.parent.css('div').select { |node| node.text == 'Summary' }
    return nil unless summary_titles.count > 0

    summary_title = summary_titles[0]

    info_text = summary_title.next_element.text
    return nil unless info_text

    info_text.split("\n").map(&:strip).join(', ').tr('"', '')
  end

  def flight_info(aircraft_id)
    extract_aircraft_info("http://flightaware.com/resources/registration/#{aircraft_id}")
  end
end
