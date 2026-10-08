class CreateGlideImportsAndOsceStationScores < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Unggah CSV hasil CBT & OSCE berformat ekspor Glide — padanan
  # /admin/glide_syncs/csv_import dan /admin/cbt_exams jejak.pro.
  #
  #   - assessment_events.external_code: kunci event dari berkas (exam_code
  #     CBT, atau "OSCE-GLIDE-2025-10-20" untuk sesi OSCE per hari), supaya
  #     unggahan ulang masuk ke event yang sama, bukan membuat event kembar.
  #   - assessment_events.exam_purpose: formatif / sumatif (kolom exam_type).
  #   - assessment_dimensions.category: kelompok tinjauan CBT (Area
  #     Kompetensi, Sistem Organ, …) untuk radar per kategori.
  #   - osce_station_scores: satu baris = satu station yang diuji (8 dimensi
  #     klinis skala 0–3, global rating, umpan balik penguji). Nilai OSCE
  #     mahasiswa di AssessmentInstance adalah rangkumannya.
  #   - glide_imports: riwayat unggahan, ringkasan, dan dasar rollback.
  def change
    create_table :glide_imports do |t|
      t.string :importer_key, null: false          # cbt | osce
      t.string :filename
      t.references :imported_by, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "completed" # completed | rolled_back
      t.integer :created_count, null: false, default: 0
      t.integer :updated_count, null: false, default: 0
      t.integer :skipped_count, null: false, default: 0
      t.integer :error_count, null: false, default: 0
      t.integer :total_rows, null: false, default: 0
      t.jsonb :skip_reasons, null: false, default: {}
      t.jsonb :error_messages, null: false, default: []
      t.jsonb :options, null: false, default: {}
      # Rekaman yang DIBUAT unggahan ini (dihapus saat rollback) dan percobaan
      # terdaftar yang diisi nilainya (dikembalikan ke "Terdaftar").
      t.jsonb :created_event_ids, null: false, default: []
      t.jsonb :created_instance_ids, null: false, default: []
      t.jsonb :filled_instance_ids, null: false, default: []
      t.datetime :rolled_back_at
      t.references :rolled_back_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_column :assessment_events, :external_code, :string
    add_column :assessment_events, :exam_purpose, :string
    add_index :assessment_events, :external_code, unique: true, where: "external_code IS NOT NULL", algorithm: :concurrently

    add_column :assessment_dimensions, :category, :string

    create_table :osce_station_scores do |t|
      t.references :assessment_instance, null: false, foreign_key: true
      t.references :examiner, foreign_key: { to_table: :users }
      t.references :glide_import, foreign_key: true
      t.string :external_row_id                     # $rowID Glide — kunci idempoten
      t.string :station
      t.string :case_title                          # kasus
      t.string :question_code                       # IDSoal
      t.jsonb :scores, null: false, default: {}     # 8 dimensi klinis, skala 0–3
      t.decimal :checklist_score, precision: 6, scale: 2 # 0–100
      t.string :global_rating
      t.text :feedback_keep                         # halBaik
      t.text :feedback_improve                      # perluDitingkatkan
      t.text :reflection                            # refleksi
      t.jsonb :details, null: false, default: {}    # diagnosis, resep, SP, institusi, …
      t.datetime :assessed_at
      t.timestamps
    end
    add_index :osce_station_scores, :external_row_id, unique: true, where: "external_row_id IS NOT NULL"
  end
end
