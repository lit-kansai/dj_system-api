# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_12_16_155420) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "AccessTokens", force: :cascade do |t|
    t.integer "user_id"
    t.string "type"
    t.string "access_token"
    t.string "refresh_token"
  end

  create_table "Letters", force: :cascade do |t|
    t.string "room_id"
    t.string "radio_name"
    t.text "message"
    t.datetime "create_at"
  end

  create_table "RoomUsers", force: :cascade do |t|
    t.integer "user_id"
    t.integer "room_id"
  end

  create_table "Rooms", force: :cascade do |t|
    t.integer "room_master_id"
    t.string "room_url"
    t.string "room_name"
    t.string "description"
    t.string "type"
    t.string "playkist_id"
    t.datetime "create_at"
  end

  create_table "Songs", force: :cascade do |t|
    t.integer "letter_id"
    t.string "song_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "is_admin"
    t.string "google_id"
    t.datetime "create_at"
  end

end
