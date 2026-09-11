# frozen_string_literal: true

class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :category, null: false # klinis | non_klinis
      t.string :activity_type
      t.date :activity_date, null: false
      t.text :description
      t.text :reflection
      t.integer :participant_count
      t.string :patient_code

      t.timestamps
    end

    add_index :activity_logs, %i[user_id activity_date]
    add_index :activity_logs, :category
  end
end
