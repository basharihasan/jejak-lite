# frozen_string_literal: true

class CreateFinalProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :final_projects do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :supervisor, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "proposal" # proposal | ongoing | completed

      t.timestamps
    end
  end
end
