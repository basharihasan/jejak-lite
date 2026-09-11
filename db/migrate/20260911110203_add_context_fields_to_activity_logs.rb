class AddContextFieldsToActivityLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :activity_logs, :location, :string
    add_column :activity_logs, :delivery_mode, :string
  end
end
