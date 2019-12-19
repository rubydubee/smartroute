class RouteStop < ApplicationRecord

  has_many :stop_route_mappings
  has_many :route_directions, through: :stop_route_mappings
  belongs_to :agency

  acts_as_mappable :default_units => :miles,
                   :default_formula => :sphere,
                   :distance_field_name => :distance,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  # my location : 37.794065, -122.267604

  # Syncs data with 511.org. 
  # Brings in all the stations and link them with the concerning route direction and agency
  def self.resync(agency=nil)
    Route.resync
    route_directions = agency.nil? ? RouteDirection : RouteDirection.where(route_id: agency.routes.map(&:id))
    route_directions.find_in_batches(batch_size: 20) do |directions|
      route_idfs = directions.map(&:route_idf)

      # Iterates through all the route directions 20 at a time, fetches all the stops for each batch of `route_idf`s
      Client511.new.stops(route_idfs)["AgencyList"].first["Agency"].each do |agency_json|
        agency = Agency.find_by_name(agency_json["Name"].strip)
        if agency.nil?
          puts "Error finding agency"
          next
        end
        agency_json["RouteList"].first["Route"].each do |route_json|
          route = agency.routes.where(code: route_json["Code"]).first
          if route.nil?
            puts "Error finding route"
            next
          end

          # BART doesn't have route directions, so a special condition check
          route_direction, stop_list =  if route_json["RouteDirectionList"].present?
                                          rd = route_json["RouteDirectionList"].first["RouteDirection"].first
                                          [route.route_directions.where(code: rd["Code"]).first, rd["StopList"].first["Stop"]]
                                        else
                                          [route.route_directions.first, route_json["StopList"].first["Stop"]]
                                        end

          if route_direction.nil?
            puts "Error finding route_direction"
            next
          end
          # Do not create same stop(with same name and code) again, create a mapping between route_stop and route_direction
          stop_list.each do |stop_json|
            stop = RouteStop.where(name: stop_json["name"], code: stop_json["StopCode"], agency_id: agency.id).first_or_create
            stop.stop_route_mappings.where(route_direction_id: route_direction.id).first_or_create
          end
        end
      end
    end
  end

  # Sets location data(latitude and longitude) for each stop for the given agency
  def self.set_locations(agency_name)
    case agency_name
    when "SF-MUNI"
      agency = Agency.find_by_name agency_name
      agency.routes.each do |route|
        muni_locations(route.code).each do |location|
          stop = agency.route_stops.where(code: location["stopId"]).first
          stop.update_attributes(latitude: location["lat"], longitude: location["lon"]) if stop
        end
      end
    when "BART"
      agency = Agency.find_by_name agency_name
      bart_locations.each do |station|
        agency.route_stops.where("name like ?",station["name"].first+"%").update_all(latitude: station["gtfs_latitude"].first, longitude: station["gtfs_longitude"].first) rescue nil
      end
      # couple of special cases for bart stations, where i couldn't get the location data from API, because of inconsistencies between station names
      JSON.parse(File.read("lib/stops_data/bart.json")).each do |name, location|
        agency.route_stops.where(name: name).update_all(latitude: location["latitude"], longitude: location["longitude"])
      end
    when "Caltrain"
      agency = Agency.find_by_name agency_name
      # Caltrain doesn't have REST api, they provide data as files AFAIK
      # This is a modified version of the file, it only has data i need
      stations = CSV.read('lib/stops_data/caltrain.csv')
      stations.each do |station|
        agency.route_stops.where("name like ? and code=?", station[1]+"%", station[0]).update_all(latitude: station[2], longitude: station[3])
      end
    when "AC Transit"
      agency = Agency.find_by_name agency_name
      agency.routes.each do |route|
        actransit_locations(route.code).each do |location|
          stop = agency.route_stops.where(code: location["stopId"]).first
          stop.update_attributes(latitude: location["lat"], longitude: location["lon"]) if stop
        end
      end
    end
  end

  # Fetch locations for all Muni stops
  def self.muni_locations(route)
    res = Typhoeus.get("http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=sf-muni&r=#{route}")
    route = XmlSimple.xml_in(res.body)
    route["route"].first["stop"]
  end

  # Fetch locations for all AC Transit stations
  def self.actransit_locations(route)
    res = Typhoeus.get("http://webservices.nextbus.com/service/publicXMLFeed?command=routeConfig&a=actransit&r=#{route}")
    route = XmlSimple.xml_in(res.body)
    route["route"].first["stop"]
  end

  # Fetch locations for all BART stations
  def self.bart_locations
    res = Typhoeus.get("http://api.bart.gov/api/stn.aspx?cmd=stns&key=MW9S-E7SL-26DU-VV8V")
    stations = XmlSimple.xml_in(res.body)
    stations["stations"].first["station"]
  end

  # Fetches departure times for the stop
  def departures
    json = Client511.new.departures(agency.name, name)
    parse_departures(json)
  end

  # Helper method to parse departure times coming from 511.org
  def parse_departures(json)
    # this will return blank if there are any failures in the API request
    return [] if json["FailedRequest"].present? or json["AgencyList"].first["Agency"].blank?

    sane_departures = Hash.new { |hash, key| hash[key] = {} }
    routes = json["AgencyList"].first["Agency"].first["RouteList"].first["Route"] rescue []
    routes.each do |route_json|
      # Again, special case for BART, it doesn't have route_direction
      if route_json["RouteDirectionList"]
        route_json["RouteDirectionList"].first["RouteDirection"].map do |dir|
          times = dir["StopList"].first["Stop"].first["DepartureTimeList"].first["DepartureTime"] rescue []
          times ||= []
          key = route_json["Name"] + " - " + dir["Name"]
          # found that, sometimes the API returns departure times greater than 90 minutes
          sane_departures[key] = {"route_idf" => "#{agency.name}~#{route_json["Code"]}~#{dir["Code"]}","times" => times.select {|t| t.to_i <= 90 }}
        end 
      else
        times = route_json["StopList"].first["Stop"].first["DepartureTimeList"].first["DepartureTime"] rescue []
        times ||= []
        key = route_json["Name"]
        # sane_departures[key] = times.select {|t| t.to_i < 90 }
        sane_departures[key] = {"route_idf" => "#{agency.name}~#{route_json["Code"]}","times" => times.select {|t| t.to_i <= 90 }}
      end
    end rescue nil
    sane_departures
  end

end
