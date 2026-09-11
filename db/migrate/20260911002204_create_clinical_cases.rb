# frozen_string_literal: true

class CreateClinicalCases < ActiveRecord::Migration[8.1]
  def change
    create_table :clinical_cases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :verified_by, foreign_key: { to_table: :users }
      t.date :case_date, null: false
      t.string :chief_complaint, null: false
      t.string :patient_age_group # Anak, Dewasa, Lansia - bukan identitas
      t.string :patient_gender
      t.text :diagnosis
      t.text :management
      t.text :learning_points
      t.string :status, null: false, default: "draft" # draft, submitted, verified, needs_revision
      t.text :verification_comment
      t.datetime :verified_at

      t.timestamps
    end

    add_index :clinical_cases, %i[user_id status]
    add_index :clinical_cases, :status
  end
end
