class CreateStopRouteMappings < ActiveRecord::Migration[6.0]
  def change
    create_table :stop_route_mappings do |t|
      t.integer :route_stop_id
      t.integer :route_direction_id
      t.timestamps
    end
    add_index :stop_route_mappings, [:route_stop_id]
    add_index :stop_route_mappings, [:route_direction_id]
  end
end
