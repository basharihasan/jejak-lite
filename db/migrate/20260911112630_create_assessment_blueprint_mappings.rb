class CreateAssessmentBlueprintMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :assessment_blueprint_mappings do |t|
      t.bigint :assessment_blueprint_id, null: false
      t.bigint :competency_item_id, null: false
      t.decimal :weight, precision: 5, scale: 2, null: false

      t.timestamps
    end

    add_index :assessment_blueprint_mappings, :assessment_blueprint_id
    add_index :assessment_blueprint_mappings, :competency_item_id
    add_index :assessment_blueprint_mappings, %i[assessment_blueprint_id competency_item_id], unique: true, name: "index_blueprint_mappings_uniq"

    safety_assured do
      add_foreign_key :assessment_blueprint_mappings, :assessment_blueprints
      add_foreign_key :assessment_blueprint_mappings, :competency_items
    end
  end
end
