# frozen_string_literal: true

class CreateAssessmentFormTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :assessment_form_templates do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, null: false, default: true
      t.boolean :anonymous, null: false, default: false
      t.boolean :requires_subject_user, null: false, default: false
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
