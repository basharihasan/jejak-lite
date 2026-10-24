# Dosen/preseptor pembimbing yang DITANDAI mahasiswa saat menulis kasus
# (opsional). Bila terisi, hanya dia yang boleh memverifikasi kasus itu —
# lihat ClinicalCasePolicy#verify?. Pola aman strong_migrations sama dengan
# 20260915080003: indeks concurrent + FK tanpa validasi (kolom baru, semua
# NULL — tidak ada baris yang perlu dicek); FK divalidasi di migrasi berikutnya.
class AddSupervisorToClinicalCases < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :clinical_cases, :supervisor, index: { algorithm: :concurrently }
    add_foreign_key :clinical_cases, :users, column: :supervisor_id, validate: false
  end
end
