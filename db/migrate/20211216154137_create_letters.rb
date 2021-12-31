class CreateLetters < ActiveRecord::Migration[6.1]
  def change
    create_table :letters do |t|
      t.integer :room_id
      t.string :radio_name
      t.text :message
      t.timestamps null: false
    end
  end
end
