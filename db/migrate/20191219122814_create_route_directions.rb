class CreateRouteDirections < ActiveRecord::Migration[6.0]
  def change
    create_table :route_directions do |t|
      t.string :name
      t.string :code
      t.integer :route_id
      t.timestamps
    end
    add_index :route_directions, [:route_id]
  end
end
