# Mini-CEX & DOPS yang diinisiasi mahasiswa dari kasus Logbook Kasus Klinis
# (Paket Dasar Pilar B, "inisiasi terintegrasi" jejak.pro). Pola aman
# strong_migrations sama dengan 20260915050001: indeks concurrent + FK
# tanpa validasi (kolom baru, semua NULL — tidak ada baris yang perlu dicek).
class AddClinicalCaseToWorkplaceEvaluations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :dops_evaluations, :clinical_case, index: { algorithm: :concurrently }
    add_foreign_key :dops_evaluations, :clinical_cases, validate: false
    add_reference :mini_cex_evaluations, :clinical_case, index: { algorithm: :concurrently }
    add_foreign_key :mini_cex_evaluations, :clinical_cases, validate: false
  end
end
