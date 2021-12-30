class CreateRooms < ActiveRecord::Migration[6.1]
  def change
      create_table :rooms do |t|
        t.integer :room_master_id
        t.string :room_url
        t.string :room_name
        t.string :description
        t.string :type
        t.string :playlist_id
        t.timestamps :created_at,null: false
      end
  end
end
