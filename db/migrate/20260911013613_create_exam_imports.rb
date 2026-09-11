# frozen_string_literal: true

class CreateExamImports < ActiveRecord::Migration[8.1]
  def change
    create_table :exam_imports do |t|
      t.string :kind, null: false # cbt | osce | progress_test
      t.string :name, null: false
      t.references :imported_by, null: false, foreign_key: { to_table: :users }
      t.integer :row_count, null: false, default: 0
      t.integer :unmatched_count, null: false, default: 0

      t.timestamps
    end
  end
end
