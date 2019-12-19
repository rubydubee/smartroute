# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_19_122826) do

  create_table "agencies", force: :cascade do |t|
    t.string "name"
    t.boolean "has_direction"
    t.string "mode"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "route_directions", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.integer "route_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["route_id"], name: "index_route_directions_on_route_id"
  end

  create_table "route_stops", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.float "latitude"
    t.float "longitude"
    t.integer "agency_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["agency_id"], name: "index_route_stops_on_agency_id"
    t.index ["latitude", "longitude"], name: "index_route_stops_on_latitude_and_longitude"
  end

  create_table "routes", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.integer "agency_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["agency_id"], name: "index_routes_on_agency_id"
  end

  create_table "stop_route_mappings", force: :cascade do |t|
    t.integer "route_stop_id"
    t.integer "route_direction_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["route_direction_id"], name: "index_stop_route_mappings_on_route_direction_id"
    t.index ["route_stop_id"], name: "index_stop_route_mappings_on_route_stop_id"
  end

end
