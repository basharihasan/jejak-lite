# frozen_string_literal: true

class CreateAssessmentFormSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :assessment_form_submissions do |t|
      t.references :assessment_form_template, null: false, foreign_key: true
      t.references :respondent, null: false, foreign_key: { to_table: :users }
      t.references :subject_user, foreign_key: { to_table: :users }
      t.string :subject_label
      t.datetime :submitted_at, null: false

      t.timestamps
    end
  end
end
