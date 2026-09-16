# Padanan "Taksonomi Istilah" jejak.pro (/admin/terminology) versi
# single-tenant: satu baris per kunci i18n yang labelnya diganti admin
# (nav.* = label menu, terms.* = istilah). Tanpa baris = pakai bawaan berkas
# locale, jadi tabel kosong berarti tampilan persis seperti sebelumnya.
class CreateTerminologyOverrides < ActiveRecord::Migration[8.1]
  def change
    create_table :terminology_overrides do |t|
      t.string :key, null: false
      t.string :value, null: false
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :terminology_overrides, :key, unique: true
  end
end
