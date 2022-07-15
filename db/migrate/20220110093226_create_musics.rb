class CreateMusics < ActiveRecord::Migration[6.1]
  def change
    create_table :musics do |t|
      t.integer :letter_id
      t.string :provided_music_id
      t.string :name
      t.string :artist
      t.string :album
      t.string :thumbnail
      t.integer :duration
      t.timestamps null: false
    end
  end
end
