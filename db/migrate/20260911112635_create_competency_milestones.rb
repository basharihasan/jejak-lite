class CreateCompetencyMilestones < ActiveRecord::Migration[8.1]
  def change
    create_table :competency_milestones do |t|
      t.bigint :competency_item_id, null: false
      t.bigint :academic_period_id, null: false
      t.integer :expected_score, null: false

      t.timestamps
    end

    add_index :competency_milestones, :competency_item_id
    add_index :competency_milestones, :academic_period_id
    add_index :competency_milestones, %i[competency_item_id academic_period_id], unique: true, name: "index_competency_milestones_uniq"

    safety_assured do
      add_foreign_key :competency_milestones, :competency_items
      add_foreign_key :competency_milestones, :academic_periods
    end
  end
end
