class CreateSongs < ActiveRecord::Migration[6.1]
  def change
      create_table :songs do |t|
        t.integer :letter_id
        t.string :song_id
        t.timestamps null: false
      end
  end
end
