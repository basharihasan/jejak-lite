# Taksonomi Logbook Kegiatan meniru jejak.pro: Domain → Subdomain (kategori)
# → Bentuk Kegiatan. Nama tabel & kolom sengaja SAMA dengan jejak.pro supaya
# paket migrasi bisa dicocokkan per nama tanpa kamus terjemahan.
#
# Kolom `is_clinical` tidak ada di jejak.pro: dipakai jejak-lite untuk
# menurunkan `activity_logs.category` (klinis/non_klinis) yang masih dibaca
# Portfolio, feed iCal, dan kode pasien anonim.
#
# Kolom penaut di activity_logs ada di migrasi berikutnya (pola aman
# strong_migrations: indeks concurrent di luar transaksi).
class CreateAcademicActivityTaxonomy < ActiveRecord::Migration[8.1]
  def change
    create_table :academic_activity_domains do |t|
      t.string :name, null: false
      t.string :icon
      t.string :color_code
      t.integer :position, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.boolean :is_clinical, null: false, default: false
      t.timestamps
    end
    add_index :academic_activity_domains, :name, unique: true

    create_table :academic_activity_subdomains do |t|
      t.references :academic_activity_domain, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :academic_activity_subdomains, %i[academic_activity_domain_id name],
              unique: true, name: "idx_activity_subdomains_unique_name"

    create_table :academic_activity_templates do |t|
      t.references :academic_activity_subdomain, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :academic_activity_templates, %i[academic_activity_subdomain_id name],
              unique: true, name: "idx_activity_templates_unique_name"
  end
end
