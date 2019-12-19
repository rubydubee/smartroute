class Agency < ApplicationRecord

  has_many :routes
  has_many :route_stops

  def self.resync
    agencies = Client511.new.agencies
    agencies["AgencyList"].first["Agency"].each do |agency| 
      Agency.where(name: agency["Name"].strip, has_direction: agency["HasDirection"].eql?("True"), mode: agency["Mode"]).first_or_create
    end
  end
end
