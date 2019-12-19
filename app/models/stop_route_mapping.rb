class StopRouteMapping < ApplicationRecord
  belongs_to :route_stop
  belongs_to :route_direction
end
