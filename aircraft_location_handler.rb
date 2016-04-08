require 'nokogiri'
require 'open-uri'
require './flight_common'
require './sms_command_handler'

class AircraftLocationHandler < SmsCommandHandler
  def can_handle?(sms_text)
    command_pieces = sms_text.split(' ')
    command_pieces.count == 2 && command_pieces[1] == 'location'
  end

  def failure_message
    'Cannot find location of this aircraft.'
  end

  def handle(sms_text)
    aircraft_id, _ = sms_text.split(' ')
    return 'Invalid aircraft id.' unless is_valid_aircraft_id?(aircraft_id)
    flight_location(aircraft_id)
  end

  private

  # This function may need to change according to the web structure changes in the scraped website.
  def extract_landed_aircraft_status(section)
    # We are aiming at find detail string in a structure like:
    #       ...
    #          <th ...>Status</th>
    #          <td ...>
    #               <span ...>Landed over 2 hours ago ...</span>
    #               ...
    #          </td>
    #          ...
    #       ...

    status_ths = section.css('th').select { |node| node.text == 'Status' }
    return nil unless status_ths.count > 0
    status_th = status_ths[0]

    status_td = status_th.next_element
    return nil unless status_td

    status_td.text.gsub('  (track log & graph)', '')
  end

  # This function may need to change according to the web structure changes in the scraped website.
  def extract_arrived_aircraft_status(section)
    # We are aiming at find detail string in a structure like:
    #       ...
    #          <th ...>Status</th>
    #          <td ...>
    #               <span ...>Arrived at gate 33 minutes ago ...</span>
    #               ...
    #          </td>
    #          ...
    #       ...

    status_ths = section.css('th').select { |node| node.text == 'Status' }
    return nil unless status_ths.count > 0
    status_th = status_ths[0]

    status_td = status_th.next_element
    return nil unless status_td

    status_td.text.gsub('  (track log & graph)', '')
  end

  # This function may need to change according to the web structure changes in the scraped website.
  def extract_en_route_aircraft_status(section)
    # We are aiming at find detail string in a structure like:
    #       ...
    #          <th ...>Status</th>
    #          <td ...>
    #               <span ...>En Route / On Time</span>
    #               <span ...>(2,182 sm down; 436 sm to go)</span>
    #               ...
    #          </td>
    #          ...
    #       ...

    status_ths = section.css('th').select { |node| node.text == 'Status' }
    return nil unless status_ths.count > 0
    status_th = status_ths[0]

    status_td = status_th.next_element
    return nil unless status_td

    status_td.text.gsub('En Route / ', '').gsub('  (track log & graph)', '')
  end

  def extract_aircraft_location(url)
    page = Nokogiri::HTML(open(url))

    airports = page.css('div.track-panel-airport')
    return nil unless airports.count > 1

    destination = airports[1].text.gsub(' – info', '').strip

    track_panels = page.css('table.track-panel-data')
    return nil unless track_panels.count > 0
    track_panel = track_panels[0]

    if !track_panel.text.index('En Route').nil?
      status = extract_en_route_aircraft_status(track_panel)
      return "En route to #{destination}. #{status}."
    elsif !track_panel.text.index('Landed').nil?
      status = extract_landed_aircraft_status(track_panel)
      return "At #{destination}. #{status}"
    elsif !track_panel.text.index('Arrived').nil?
      status = extract_arrived_aircraft_status(track_panel)
      return "At #{destination}. #{status}"
    else
      return "At #{destination}. Status unknown."
    end
  end

  def flight_location(aircraft_id)
    extract_aircraft_location("http://flightaware.com/live/flight/#{aircraft_id}")
  end
end
