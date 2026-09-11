class AddContextFieldsToClinicalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :clinical_cases, :clinical_setting, :string
    add_column :clinical_cases, :case_complexity, :string
    add_column :clinical_cases, :entrustment_level, :string
    add_column :clinical_cases, :recommend_remediation, :boolean, default: false, null: false
  end
end
