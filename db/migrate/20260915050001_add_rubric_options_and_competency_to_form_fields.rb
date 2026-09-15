class AddRubricOptionsAndCompetencyToFormFields < ActiveRecord::Migration[8.1]
  # Form Builder naik dari "kuesioner + skala angka" menjadi rubrik sungguhan:
  #   - `options` menyimpan jenjang rubrik (label + deskriptor + skor) atau
  #     pilihan untuk tipe select;
  #   - `competency_item_id` menandai pertanyaan ini menilai ranah kompetensi
  #     apa, sehingga nilai rubrik ikut mengisi Peta Kompetensi — sejajar
  #     dengan pemetaan dimensi ujian (AssessmentDimension#competency_item).
  disable_ddl_transaction!

  def change
    add_column :assessment_form_fields, :options, :jsonb, null: false, default: []
    add_reference :assessment_form_fields, :competency_item, index: { algorithm: :concurrently }
    add_foreign_key :assessment_form_fields, :competency_items, validate: false
  end
end
