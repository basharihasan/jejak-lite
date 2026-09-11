# frozen_string_literal: true

class CreateAssessmentFormFields < ActiveRecord::Migration[8.1]
  def change
    create_table :assessment_form_fields do |t|
      t.references :assessment_form_template, null: false, foreign_key: true
      t.string :label, null: false
      t.string :field_type, null: false # rating | text | textarea | yes_no
      t.integer :position, null: false, default: 0
      t.boolean :required, null: false, default: true

      t.timestamps
    end
  end
end
