# Kolom baru Logbook Kegiatan mengikuti form jejak.pro: taksonomi 3 tingkat,
# waktu mulai/selesai, semester, rotasi klinik, dan tautan bukti & dokumen.
# Pola aman strong_migrations sama dengan 20260915080003: indeks concurrent +
# FK tanpa validasi; validasinya di migrasi berikutnya.
class AddTaxonomyAndContextToActivityLogs < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  REFERENCES = {
    academic_activity_domain: :academic_activity_domains,
    academic_activity_subdomain: :academic_activity_subdomains,
    academic_activity_template: :academic_activity_templates,
    academic_period: :academic_periods,
    clinical_rotation: :clinical_rotations
  }.freeze

  def change
    add_column :activity_logs, :started_at, :datetime
    add_column :activity_logs, :ended_at, :datetime
    add_column :activity_logs, :evidence_url, :string
    add_column :activity_logs, :document_url, :string

    REFERENCES.each do |name, table|
      add_reference :activity_logs, name, index: { algorithm: :concurrently }
      add_foreign_key :activity_logs, table, column: "#{name}_id", validate: false
    end
  end
end
