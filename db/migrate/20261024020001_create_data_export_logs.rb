class CreateDataExportLogs < ActiveRecord::Migration[8.1]
  # Jejak audit Pusat Ekspor Data: siapa mengunduh dataset apa, dengan filter
  # apa, berapa baris. Ekspor massal data mahasiswa adalah tindakan yang harus
  # bisa dipertanggungjawabkan, sama seperti Break Glass.
  def change
    create_table :data_export_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :dataset, null: false
      t.jsonb :filters, null: false, default: {}
      t.integer :row_count, null: false, default: 0
      t.timestamps
    end
    add_index :data_export_logs, :created_at
  end
end
