class CreateRoomuser < ActiveRecord::Migration[6.1]
  def change
    create_table :RoomUsers do |t|
      t.integer :user_id
      t.integer :room_id
    end
  end
end
