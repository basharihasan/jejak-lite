class CreateEvaluationSchedules < ActiveRecord::Migration[8.1]
  # Jadwal DOPS & Mini-CEX (Konfigurasi → Jadwal DOPS & Mini-CEX) — rencana
  # penilaian WBA per mahasiswa/penilai/rotasi; dicentang "selesai" saat
  # evaluasinya sudah tersubmit.
  def change
    create_table :evaluation_schedules do |t|
      t.string :kind, null: false                              # dops / mini_cex
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :evaluator, foreign_key: { to_table: :users }
      t.references :clinical_rotation, foreign_key: true
      t.datetime :scheduled_at, null: false
      t.string :topic
      t.string :status, null: false, default: "planned"        # planned / done / cancelled
      t.text :notes
      t.timestamps
    end
    add_index :evaluation_schedules, [ :student_id, :scheduled_at ]
    add_index :evaluation_schedules, [ :evaluator_id, :status ]
  end
end
