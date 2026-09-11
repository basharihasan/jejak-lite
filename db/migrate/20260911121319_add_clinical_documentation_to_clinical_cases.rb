class AddClinicalDocumentationToClinicalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :clinical_cases, :anamnesis, :text
    add_column :clinical_cases, :general_condition, :text
    add_column :clinical_cases, :physical_examination, :text
    add_column :clinical_cases, :family_history, :text
    add_column :clinical_cases, :vital_signs, :jsonb, default: {}, null: false
  end
end
