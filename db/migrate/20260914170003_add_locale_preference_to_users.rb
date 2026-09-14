class AddLocalePreferenceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :locale_preference, :string, default: "id", null: false
  end
end
