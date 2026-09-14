class CreateMedicationsAndPrescriptionItems < ActiveRecord::Migration[8.1]
  # Latihan menulis resep pada Logbook Kasus Klinis. Master obat mengikuti
  # pola master Diagnosis/Keterampilan (datalist + impor CSV); baris resep
  # disimpan terstruktur supaya bisa ditampilkan ulang dalam format R/ dan
  # diperiksa preseptor, bukan sekadar teks bebas di kolom tatalaksana.
  def change
    create_table :medication_definitions do |t|
      t.string :name, null: false            # nama generik, mis. "Parasetamol"
      t.string :strength                     # "500 mg"
      t.string :dosage_form                  # tablet / kapsul / sirup / injeksi
      t.string :category                     # kelas terapi, mis. "Analgesik-Antipiretik"
      t.string :usual_dosage                 # anjuran lazim, mis. "3-4 x 500 mg"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :medication_definitions, "LOWER(name), COALESCE(strength, '')", unique: true, name: "idx_medication_definitions_unique"

    create_table :prescription_items do |t|
      t.references :clinical_case, null: false, foreign_key: true
      t.string :medication_name, null: false
      t.string :strength
      t.string :dosage_form
      t.string :quantity                     # "X" / "10" — ditulis apa adanya
      t.string :signa                        # aturan pakai, mis. "3 dd tab I p.c."
      t.string :route                        # oral / topikal / injeksi ...
      t.string :notes
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
