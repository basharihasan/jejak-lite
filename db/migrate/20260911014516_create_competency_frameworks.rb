# frozen_string_literal: true

class CreateCompetencyFrameworks < ActiveRecord::Migration[8.1]
  def change
    create_table :competency_frameworks do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
  end
end
