class CreateAccesstoken < ActiveRecord::Migration[6.1]
  def change
    create_table :AccessTokens do |t|
      t.integer :user_id
      t.string :type
      t.string :access_token
      t.string :refresh_token
    end
  end
end
