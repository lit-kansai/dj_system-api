class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.boolean :is_admin, null: false, default: false
      t.string :google_id
      t.timestamps null: false
    end
  end
end
