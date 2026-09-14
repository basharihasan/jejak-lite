class AddDisplayPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :theme_preference, :string, default: "system", null: false
    add_column :users, :font_size_preference, :string, default: "normal", null: false
  end
end
