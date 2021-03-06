require 'rubygems'
require 'twilio-ruby'
require 'sinatra'
require 'logger'

require './sms_command_handler'
require './aircraft_info_handler'
require './aircraft_location_handler'
require './location_weather_handler'

def send_sms(text)
  twiml = Twilio::TwiML::Response.new do |r|
    r.Message text
  end
  twiml.text
end

def handleSmsCommand(sms_text)
  handlers = [
    AircraftInfoHandler.new,
    AircraftLocationHandler.new,
    LocationWeatherHandler.new,
    # default handler:
    SmsCommandHandler.new]

  handlers.each do |handler|
    next unless handler.can_handle?(sms_text)
    response = handler.handle(sms_text)
    response = handler.failure_message if response.nil?
    Logger.new(STDOUT).debug "Command \"#{sms_text}\" is handled by #{handler.class}.\nResponse: #{response}"
    return response
  end
end

get '/sms-inbound' do
  send_sms(handleSmsCommand(params[:Body]))
end
