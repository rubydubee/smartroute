# Helper class for making API requests to 511.org RTT api
class Client511
  def initialize
    @secret_token = ENV['SECRET_511']
    @host = "http://services.my511.org/Transit2.0"
  end

  # Makes the api request, asks for end_point(like GetAgencies, GetStopsForRoutes, etc) and required params 
  # No need to pass token parameter.
  def get(endpoint, params={})
    res = Typhoeus.get("#{@host}/#{endpoint}.aspx", params: params.merge({token: @secret_token}))
    if res.success?
      json = XmlSimple.xml_in(res.body)
      return {"FailedRequest" => true} unless json.is_a?(Hash)
      json
    else
      {"FailedRequest" => true}
    end
  end

  def agencies
    get("GetAgencies")
  end

  # Fetches routes for the given agency names, 
  # if agency_names are not specifed, it will return routes for all agencies
  def routes(agency_names = nil)
    agency_names ||= agencies["AgencyList"].first["Agency"].map{|ag| ag["Name"].strip }
    get('GetRoutesForAgencies', {"agencyNames"=>agency_names.join("|")})
  end

  def stops(route_idfs)
    get('GetStopsForRoutes', {"routeIDF"=>route_idfs.join("|")})
  end

  def departures(agency_name, stop_name)
    get('GetNextDeparturesByStopName', {'agencyName' => agency_name, 'stopName' => stop_name})
  end
end