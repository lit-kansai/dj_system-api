class CreateRooms < ActiveRecord::Migration[6.1]
  def change
      create_table :rooms do |t|
        t.integer :owner_user_id
        t.string :display_id
        t.string :name
        t.string :description
        t.string :type
        t.string :playlist_id
        t.timestamps null: false
      end
  end
end
