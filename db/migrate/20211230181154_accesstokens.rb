class Accesstokens < ActiveRecord::Migration[6.1]
  def change
    create_table :access_tokens do |t|
      t.integer :user_id
      t.string :type
      t.string :access_token
      t.string :refresh_token
      t.timestamps null: false
    end
  end
end
