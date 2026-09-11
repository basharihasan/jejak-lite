# frozen_string_literal: true

class CreateMiniCexEvaluations < ActiveRecord::Migration[8.1]
  def change
    create_table :mini_cex_evaluations do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :evaluator, null: false, foreign_key: { to_table: :users }
      t.references :clinical_rotation, null: false, foreign_key: true
      t.string :case_description, null: false
      t.date :evaluated_at, null: false
      t.jsonb :scores, null: false, default: {}
      t.text :overall_feedback

      t.timestamps
    end

    add_index :mini_cex_evaluations, %i[student_id evaluated_at]
  end
end
