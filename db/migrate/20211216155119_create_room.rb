class CreateRoom < ActiveRecord::Migration[6.1]
  def change
      create_table :Rooms do |t|
        t.integer :room_master_id
        t.string :room_url
        t.string :room_name
        t.string :description
        t.string :type
        t.string :playkist_id
        t.datetime :create_at
      end
  end
end
