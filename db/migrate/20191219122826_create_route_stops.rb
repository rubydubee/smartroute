class CreateRouteStops < ActiveRecord::Migration[6.0]
  def change
    create_table :route_stops do |t|
      t.string :name
      t.string :code
      t.float :latitude
      t.float :longitude
      t.integer :agency_id
      t.timestamps
    end
    add_index :route_stops, :agency_id
    add_index :route_stops, [:latitude, :longitude]
  end
end
