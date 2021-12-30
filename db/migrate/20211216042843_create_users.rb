class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.boolean :is_admin
      t.string :google_id
      t.timestamps :created_at ,null: false
    end
  end
end
