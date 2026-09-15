# Penanda terverifikasi untuk Logbook Kegiatan (Paket Dasar M02: "Kalender
# kegiatan berpenanda verifikasi"). Sebelum migrasi ini ActivityLog sama
# sekali tanpa mekanisme verifikasi — beda dari ClinicalCase yang sudah
# punya alurnya sejak Fase 5. Pola aman strong_migrations sama dengan
# 20260915080002: indeks concurrent + FK tanpa validasi (kolom baru, semua
# NULL, tidak ada baris untuk dicek).
class AddVerificationToActivityLogs < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :activity_logs, :verified_at, :datetime
    add_reference :activity_logs, :verified_by, index: { algorithm: :concurrently }
    add_foreign_key :activity_logs, :users, column: :verified_by_id, validate: false
  end
end
