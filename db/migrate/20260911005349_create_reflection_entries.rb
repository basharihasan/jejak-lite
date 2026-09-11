# frozen_string_literal: true

class CreateReflectionEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :reflection_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :entry_date, null: false
      t.string :title
      t.text :content, null: false
      t.references :activity_log, foreign_key: true
      t.references :clinical_case, foreign_key: true

      t.timestamps
    end

    add_index :reflection_entries, %i[user_id entry_date]
  end
end
