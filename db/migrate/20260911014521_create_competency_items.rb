# frozen_string_literal: true

class CreateCompetencyItems < ActiveRecord::Migration[8.1]
  def change
    create_table :competency_items do |t|
      t.references :competency_framework, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :competency_items } # pohon 2 level: domain -> sub-kompetensi
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
