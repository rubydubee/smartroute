class CreateRoutes < ActiveRecord::Migration[6.0]
  def change
    create_table :routes do |t|
      t.string :name
      t.string :code
      t.integer :agency_id
      t.timestamps
    end
    add_index :routes, [:agency_id]
  end
end
