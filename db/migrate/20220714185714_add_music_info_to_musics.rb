class AddMusicInfoToMusics < ActiveRecord::Migration[7.0]
  def change
    add_column :music, :name, :string
    add_column :music, :artist, :string
    add_column :music, :album, :string
    add_column :music, :thumbnail, :string
    add_column :music, :duration, :integer
  end
end
