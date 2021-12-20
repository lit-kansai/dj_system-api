class CreateLetter < ActiveRecord::Migration[6.1]
  def change
    create_table :Letters do |t|
      t.string :room_id
      t.string :radio_name
      t.text :message
      t.datetime :create_at
    end
  end
end
