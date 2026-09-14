class CreateAssessmentEventsAndInstances < ActiveRecord::Migration[8.1]
  # Fase 25 — Pilar B. AssessmentEvent + AssessmentInstance menggantikan
  # ExamImport/ExamScore (Fase 12): satu sistem untuk nilai impor (CBT/OSCE/
  # Progress Test), asesmen berbasis rubrik penguji, CBD, dan Long Case.
  # Data lama DISALIN ke tabel baru; tabel exam_imports/exam_scores sengaja
  # tidak dihapus di sini (hapus manual setelah verifikasi data di produksi).
  def up
    create_table :assessment_events do |t|
      t.string :name, null: false
      t.string :assessment_type, null: false
      t.references :academic_period, null: false, foreign_key: true
      t.references :study_program, foreign_key: true          # nil = semua prodi
      t.string :block_name                                    # nil = semua blok/stase
      t.date :exam_date
      t.string :status, null: false, default: "draft"         # draft / published / closed
      t.decimal :max_score, precision: 6, scale: 2, null: false, default: 100
      t.boolean :allow_multiple_attempts, null: false, default: false
      t.datetime :submission_close_at
      t.references :assessment_form_template, foreign_key: true
      t.text :description
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :assessment_events, [ :academic_period_id, :assessment_type ]

    create_table :assessment_instances do |t|
      t.references :assessment_event, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.integer :attempt_number, null: false, default: 1
      t.string :status, null: false, default: "registered"    # registered / submitted / scored
      t.decimal :score, precision: 6, scale: 2
      t.decimal :max_score, precision: 6, scale: 2, null: false, default: 100
      t.string :source, null: false, default: "manual"        # import / manual / rubric
      t.references :examiner, foreign_key: { to_table: :users }
      t.references :clinical_case, foreign_key: true          # CBD / Long Case
      t.references :assessment_form_submission, foreign_key: true
      t.datetime :scheduled_at
      t.datetime :submitted_at
      t.datetime :scored_at
      t.text :self_evaluation
      t.text :feedback_keep
      t.text :feedback_improve
      t.timestamps
    end
    add_index :assessment_instances, [ :assessment_event_id, :student_id, :attempt_number ],
              unique: true, name: "idx_assessment_instances_unique_attempt"
    add_index :assessment_instances, [ :student_id, :status ]

    # ── Salin data lama: ExamImport → AssessmentEvent, ExamScore → AssessmentInstance ──
    safety_assured do
      execute(<<~SQL)
        INSERT INTO assessment_events (name, assessment_type, academic_period_id, exam_date, status, max_score, description, created_by_id, created_at, updated_at)
        SELECT ei.name,
               CASE ei.kind WHEN 'cbt' THEN 'cbt' WHEN 'osce' THEN 'osce' ELSE 'progress_test' END,
               COALESCE(
                 (SELECT ap.id FROM academic_periods ap
                   WHERE ap.start_date <= COALESCE((SELECT MIN(es.exam_date) FROM exam_scores es WHERE es.exam_import_id = ei.id), ei.created_at::date)
                     AND ap.end_date   >= COALESCE((SELECT MIN(es.exam_date) FROM exam_scores es WHERE es.exam_import_id = ei.id), ei.created_at::date)
                   ORDER BY ap.start_date DESC LIMIT 1),
                 (SELECT ap.id FROM academic_periods ap ORDER BY ap.start_date DESC LIMIT 1)
               ),
               (SELECT MIN(es.exam_date) FROM exam_scores es WHERE es.exam_import_id = ei.id),
               'published',
               COALESCE((SELECT MAX(es.max_score) FROM exam_scores es WHERE es.exam_import_id = ei.id), 100),
               'Dimigrasikan dari Impor Nilai Ujian #' || ei.id,
               ei.imported_by_id, ei.created_at, ei.updated_at
        FROM exam_imports ei
        WHERE EXISTS (SELECT 1 FROM academic_periods)
      SQL

      execute(<<~SQL)
        INSERT INTO assessment_instances (assessment_event_id, student_id, attempt_number, status, score, max_score, source, scored_at, created_at, updated_at)
        SELECT ae.id, es.student_id,
               ROW_NUMBER() OVER (PARTITION BY ae.id, es.student_id ORDER BY es.exam_date, es.id),
               'scored', es.score, es.max_score, 'import', es.exam_date::timestamp, es.created_at, es.updated_at
        FROM exam_scores es
        JOIN exam_imports ei ON ei.id = es.exam_import_id
        JOIN assessment_events ae ON ae.description = 'Dimigrasikan dari Impor Nilai Ujian #' || ei.id
      SQL

      execute("UPDATE assessment_events SET allow_multiple_attempts = TRUE WHERE id IN (SELECT assessment_event_id FROM assessment_instances WHERE attempt_number > 1)")
    end
  end

  def down
    drop_table :assessment_instances
    drop_table :assessment_events
  end
end
