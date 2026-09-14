class CreateEntrustmentDecisions < ActiveRecord::Migration[8.1]
  # Peta EPA & Tingkat Entrustment: level 1–5 per (mahasiswa × ranah kompetensi
  # / EPA) dengan riwayat supersede — penilaian baru menggantikan, tidak
  # menimpa. Terisi otomatis dari verifikasi kasus (EPA yang dipilih verifier)
  # atau manual oleh pembimbing.
  def change
    create_table :entrustment_decisions do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :competency_item, null: false, foreign_key: true
      t.integer :level, null: false
      t.text :justification, null: false
      t.references :decided_by, null: false, foreign_key: { to_table: :users }
      t.references :clinical_case, foreign_key: true
      t.references :superseded_by, foreign_key: { to_table: :entrustment_decisions }
      t.datetime :superseded_at
      t.timestamps
    end
    add_index :entrustment_decisions, [ :student_id, :competency_item_id, :superseded_at ], name: "idx_entrustment_current_lookup"
  end
end
