# frozen_string_literal: true

class CreateAssessmentFormAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :assessment_form_answers do |t|
      t.references :assessment_form_submission, null: false, foreign_key: true
      t.references :assessment_form_field, null: false, foreign_key: true
      t.string :value

      t.timestamps
    end
  end
end
