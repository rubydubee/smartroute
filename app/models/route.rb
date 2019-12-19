class Route < ApplicationRecord
  belongs_to :agency
  has_many :route_directions

  # Syncs all the routes for all the agencies in the database
  def self.resync
    Agency.resync
    all_routes = Client511.new.routes
    all_routes["AgencyList"].first["Agency"].each do |agency_json|
      agency = Agency.where(name: agency_json["Name"]).first
      if agency
        agency_json["RouteList"].first["Route"].each do |route_json|
          route = agency.routes.where(name: route_json["Name"], code: route_json["Code"]).first_or_create
          if route_json["RouteDirectionList"]
            route_json["RouteDirectionList"].first["RouteDirection"].each do |route_dir_json|
              route.route_directions.where(name: route_dir_json["Name"], code: route_dir_json["Code"]).first_or_create
            end
          else
            # Creates a default blank route direction for consistency
            route.route_directions.where(name: "Default", code: nil).first_or_create
          end
        end
      end
    end
  end

end
