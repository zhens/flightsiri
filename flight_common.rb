# only allow alphanumeric capital form.
def is_valid_aircraft_id?(aircraft_id)
  !/^[A-Z0-9]+$/.match(aircraft_id).nil?
end

# only allow alphabeta captical form.
def is_valid_location_id?(location_id)
  !/^[A-Z]+$/.match(location_id).nil?
end
