# frozen_string_literal: true

class CreateDopsEvaluations < ActiveRecord::Migration[8.1]
  def change
    create_table :dops_evaluations do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :evaluator, null: false, foreign_key: { to_table: :users }
      t.references :clinical_rotation, null: false, foreign_key: true
      t.string :procedure_name, null: false
      t.date :evaluated_at, null: false
      t.jsonb :scores, null: false, default: {}
      t.text :overall_feedback

      t.timestamps
    end

    add_index :dops_evaluations, %i[student_id evaluated_at]
  end
end
