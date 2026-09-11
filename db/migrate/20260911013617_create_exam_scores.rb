# frozen_string_literal: true

class CreateExamScores < ActiveRecord::Migration[8.1]
  def change
    create_table :exam_scores do |t|
      t.references :exam_import, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.decimal :score, precision: 6, scale: 2, null: false
      t.decimal :max_score, precision: 6, scale: 2, null: false, default: 100
      t.date :exam_date, null: false

      t.timestamps
    end

    add_index :exam_scores, %i[student_id exam_date]
  end
end
