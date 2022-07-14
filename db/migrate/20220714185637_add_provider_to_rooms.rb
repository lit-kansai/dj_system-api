class AddProviderToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :provider, :string
  end
end
