class CreateMasterDataAndConsentsAndTargets < ActiveRecord::Migration[8.1]
  def change
    # Master Diagnosis (SKDI + ICD-10) — sumber datalist wizard kasus klinis.
    create_table :diagnosis_definitions do |t|
      t.string :name, null: false
      t.string :icd10_code
      t.string :skdi_level            # 1, 2, 3A, 3B, 4A
      t.string :system_group          # mis. "Respirasi", "Kardiovaskular"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :diagnosis_definitions, "LOWER(name)", unique: true, name: "idx_diagnosis_definitions_lower_name"
    add_index :diagnosis_definitions, :icd10_code

    # Master Keterampilan Klinis (SKDI) — sumber datalist DOPS.
    create_table :skill_definitions do |t|
      t.string :name, null: false
      t.string :skdi_level            # 1, 2, 3, 4A
      t.string :category              # mis. "Prosedur Diagnostik", "Terapeutik"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :skill_definitions, "LOWER(name)", unique: true, name: "idx_skill_definitions_lower_name"

    # Persetujuan pasien lewat QR/tautan tanpa login.
    create_table :patient_consents do |t|
      t.references :clinical_case, null: false, foreign_key: true, index: { unique: true }
      t.string :token, null: false
      t.jsonb :items, null: false, default: {}   # education/photo/publication → true/false
      t.string :signer_name
      t.string :signer_relation                  # pasien / wali
      t.datetime :signed_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :patient_consents, :token, unique: true

    # Target volume kasus logbook per prodi & jenis fasilitas (FKTP/FKRTL).
    create_table :logbook_case_targets do |t|
      t.references :study_program, null: false, foreign_key: true
      t.references :academic_period, foreign_key: true
      t.string :facility_type, null: false       # fktp / fkrtl
      t.integer :target_count, null: false, default: 0
      t.text :notes
      t.timestamps
    end
    add_index :logbook_case_targets, [ :study_program_id, :academic_period_id, :facility_type ],
              unique: true, name: "idx_logbook_case_targets_unique"
  end
end
