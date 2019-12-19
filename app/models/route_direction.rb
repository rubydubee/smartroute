class RouteDirection < ApplicationRecord
  belongs_to :route
  has_many :stop_route_mappings
  has_many :route_stops, through: :stop_route_mappings

  def route_idf
    idf = "#{route.agency.name}~#{route.code}"
    idf += "~#{code}" if code.present?
    idf
  end
end
