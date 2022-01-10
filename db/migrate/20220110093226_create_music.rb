class CreateMusic < ActiveRecord::Migration[6.1]
  def change
    create_table :music do |t|
      t.integer :letter_id
      t.string :provided_music_id
      t.timestamps null: false
    end
  end
end
