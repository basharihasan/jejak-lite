class CreateLearningUnitsAndAssessmentMappings < ActiveRecord::Migration[8.1]
  # Fase 26 — Pilar C. Learning Unit (blok/modul) + Assessment Matrix:
  # nilai blok disusun dari beberapa Assessment Event dengan bobot, lalu
  # dipetakan ke ranah kompetensi lewat AssessmentBlueprint yang sudah ada.
  def change
    create_table :learning_units do |t|
      t.string :name, null: false
      t.string :code
      t.references :study_program, null: false, foreign_key: true
      t.references :academic_period, foreign_key: true
      t.integer :credits
      t.text :description
      t.references :assessment_blueprint, foreign_key: true
      t.timestamps
    end
    add_index :learning_units, [ :study_program_id, :academic_period_id, :name ], unique: true, name: "idx_learning_units_unique"

    create_table :assessment_mappings do |t|
      t.references :learning_unit, null: false, foreign_key: true
      t.references :assessment_event, null: false, foreign_key: true
      t.decimal :weight, precision: 5, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :assessment_mappings, [ :learning_unit_id, :assessment_event_id ], unique: true, name: "idx_assessment_mappings_unique"
  end
end
