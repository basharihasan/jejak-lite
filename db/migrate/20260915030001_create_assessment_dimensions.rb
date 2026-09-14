class CreateAssessmentDimensions < ActiveRecord::Migration[8.1]
  # Dimensi asesmen — mata uji CBT ("Penalaran Klinis", "Literasi Sains") atau
  # station OSCE ("Station 3 — Anamnesis"). Nilainya diimpor per dimensi, dan
  # tiap dimensi dipetakan ke ranah kompetensi sehingga Peta Kompetensi terisi
  # dari hasil ujian yang sebenarnya, bukan proksi rata-rata keseluruhan.
  def change
    create_table :assessment_dimensions do |t|
      t.references :assessment_event, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code                                   # nomor station / kode mata uji
      t.references :competency_item, foreign_key: true # pemetaan ke ranah kompetensi
      t.decimal :weight, precision: 6, scale: 2, null: false, default: 1
      t.decimal :max_score, precision: 6, scale: 2, null: false, default: 100
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :assessment_dimensions, [ :assessment_event_id, :name ], unique: true, name: "idx_assessment_dimensions_unique_name"

    create_table :assessment_dimension_scores do |t|
      t.references :assessment_instance, null: false, foreign_key: true
      t.references :assessment_dimension, null: false, foreign_key: true
      t.decimal :score, precision: 6, scale: 2, null: false
      t.timestamps
    end
    add_index :assessment_dimension_scores, [ :assessment_instance_id, :assessment_dimension_id ],
              unique: true, name: "idx_dimension_scores_unique"
  end
end
