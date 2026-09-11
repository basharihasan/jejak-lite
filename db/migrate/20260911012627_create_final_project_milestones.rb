# frozen_string_literal: true

class CreateFinalProjectMilestones < ActiveRecord::Migration[8.1]
  def change
    create_table :final_project_milestones do |t|
      t.references :final_project, null: false, foreign_key: true
      t.string :title, null: false
      t.date :target_date, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
