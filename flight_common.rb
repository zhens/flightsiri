def is_valid_aircraft_id?(aircraft_id)
  !/[A-Z0-9]+/.match(aircraft_id).nil?
end

def is_valid_location_id?(location_id)
  !/[A-Z][A-Z][A-Z][A-Z]/.match(location_id).nil?
end
