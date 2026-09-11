# frozen_string_literal: true

class CreateStudyPrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :study_programs do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :study_programs, :name, unique: true
  end
end
