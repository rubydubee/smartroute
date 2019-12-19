class AgenciesController < ApplicationController
  # Home page
  def landing
  end

  # Lists agencies, only four for now, since I only have location data for those.
  def index
  end

  # Main page for show a selection list for all stops, and shows departure times on selection
  def show
    @agency = Agency.where("lower(name)=?", CGI.unescape(params[:link])).first
    unless @agency
      redirect_to "/agencies"
    end
  end

  # Finds the closest stop of a given agency for the given latitude and longitude
  def closest
    # using geokit-rails helper method to find the `closest` location
    stop = RouteStop.where("latitude is not null and agency_id=?", params[:id]).closest(origin: [params[:latitude], params[:longitude]]).first
    respond_to do |format|
      if stop
        format.json { render json: stop }
      else
        format.json { head :not_found }
      end
    end
  end

  # Returns departure times for all the routes at the given stop
  def departures
    @agency = Agency.find_by_id(params[:id])
    respond_to do |format|
      if @agency
        @route_stop = @agency.route_stops.where(name: params[:stop_name]).first
        if @route_stop
          @departures = @route_stop.departures
          @view_id = "departures"
          format.js {}
        end
      end
    end
  end

  # Returns departure times for all the given routes at the given stop
  def route_departures
    respond_to do |format|
      routes = params[:routes].split("|") if params[:routes].present?
      if routes.present?
        @agency = Agency.find_by_name(routes.first.split("~").first)
        if @agency
          @route_stop = @agency.route_stops.where(name: params[:stop_name]).first
          if @route_stop
            @view_id = params[:view_id]
            @departures = @route_stop.departures.select{|k,v| v["route_idf"] && routes.include?(v["route_idf"]) }
            format.js { render :departures }
          end
        end
      end
    end
  end

  # Lists favorites
  def favorites
    # There is nothing on the server for favorites, everything stays on the client side in localStorage
  end
end
