# frozen_string_literal: true

class CreateAcademicPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :academic_periods do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end
  end
end
