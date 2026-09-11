class CreateActivityLogCompetencyTags < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_log_competency_tags do |t|
      t.bigint :activity_log_id, null: false
      t.bigint :competency_item_id, null: false

      t.timestamps
    end

    add_index :activity_log_competency_tags, :activity_log_id
    add_index :activity_log_competency_tags, :competency_item_id
    add_index :activity_log_competency_tags, %i[activity_log_id competency_item_id], unique: true, name: "index_activity_log_competency_tags_uniq"

    safety_assured do
      add_foreign_key :activity_log_competency_tags, :activity_logs
      add_foreign_key :activity_log_competency_tags, :competency_items
    end
  end
end
