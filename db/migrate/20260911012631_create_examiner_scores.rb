# frozen_string_literal: true

class CreateExaminerScores < ActiveRecord::Migration[8.1]
  def change
    create_table :examiner_scores do |t|
      t.references :final_project, null: false, foreign_key: true
      t.references :examiner, null: false, foreign_key: { to_table: :users }
      t.date :session_date, null: false
      t.decimal :score, precision: 5, scale: 2, null: false
      t.text :feedback

      t.timestamps
    end
  end
end
