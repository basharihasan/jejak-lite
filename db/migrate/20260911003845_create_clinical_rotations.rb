# frozen_string_literal: true

class CreateClinicalRotations < ActiveRecord::Migration[8.1]
  def change
    create_table :clinical_rotations do |t|
      t.references :user, null: false, foreign_key: true # mahasiswa
      t.references :academic_period, null: false, foreign_key: true
      t.references :preceptor, foreign_key: { to_table: :users }
      t.string :station_name, null: false # Bagian/Departemen, mis. "Ilmu Penyakit Dalam"
      t.string :institution_name
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    add_index :clinical_rotations, %i[user_id start_date]
  end
end
