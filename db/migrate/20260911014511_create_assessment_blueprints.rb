# frozen_string_literal: true

# Berdiri sendiri tanpa FK apa pun — meniru AssessmentBlueprint JEJAK yang
# juga tidak berasosiasi ke tabel lain (rencana penilaian, bukan data hasil).
class CreateAssessmentBlueprints < ActiveRecord::Migration[8.1]
  def change
    create_table :assessment_blueprints do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :competency_mapping, null: false, default: {} # {"Anamnesis" => 20, "Diagnosis" => 30, ...} bobot %
      t.jsonb :learning_outcomes, null: false, default: [] # ["Mampu melakukan anamnesis", ...]

      t.timestamps
    end
  end
end
