class CreateSong < ActiveRecord::Migration[6.1]
  def change
      create_table :Songs do |t|
        t.integer :letter_id
        t.string :song_id
      end
  end
end
