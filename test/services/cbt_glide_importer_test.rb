require "test_helper"

# Impor "CBT Exam Results" berformat ekspor Glide (data_cbt_exams_glide.csv).
class CbtGlideImporterTest < ActiveSupport::TestCase
  HEADER = "email,exam_code,exam_title,exam_type,total_score,held_at,rowid,Komunikasi efektif,Saraf dan Perilaku,Kognitif,Kolom Baru\n".freeze

  setup do
    @siti = users(:siti)
    @andi = User.create!(full_name: "Andi", email: "andi@example.com", password: "password123", confirmed_at: Time.current)
    @andi.roles << roles(:mahasiswa)
    @period = academic_periods(:current_period)
  end

  def import(csv, **options)
    record = GlideImport.create!(importer_key: "cbt", filename: "data_cbt_exams_glide.csv", imported_by: users(:budi))
    CbtGlideImporter.new(csv_text: csv, glide_import: record, user: users(:budi), **options).call
  end

  def exam_date = 3.days.ago.to_date

  def rows
    HEADER +
      "siti@example.com,CBT-UJI-1,Ujian CBT Uji,summative,72.5,#{exam_date.iso8601},r1,80,65.22,70,55\n" \
      "ANDI@example.com ,CBT-UJI-1,Ujian CBT Uji,summative,\"61,5\",#{exam_date.iso8601},r2,60,-,50,\n" \
      "dosen.nyasar@example.com,CBT-UJI-1,Ujian CBT Uji,summative,90,#{exam_date.iso8601},r3,90,90,90,90\n"
  end

  test "membuat event per exam_code dengan dimensi berkategori dan nilai per mahasiswa" do
    result = import(rows)

    assert_equal 3, result.total_rows
    assert_equal 2, result.created_count
    assert_equal({ "mahasiswa_tidak_ditemukan" => 1 }, result.skip_reasons)
    assert_equal 0, result.error_count, result.error_messages.inspect

    event = AssessmentEvent.find_by!(external_code: "CBT-UJI-1")
    assert_equal [ event.id ], result.created_event_ids
    assert_equal "Ujian CBT Uji", event.name
    assert_equal "cbt", event.assessment_type
    assert_equal "summative", event.exam_purpose
    assert_equal exam_date, event.exam_date
    assert_equal @period, event.academic_period, "periode = periode yang memuat tanggal ujian"
    assert_equal "published", event.status

    categories = event.assessment_dimensions.to_h { |d| [ d.name, d.category ] }
    assert_equal({ "Komunikasi efektif" => "kompetensi", "Saraf dan Perilaku" => "sistem_organ",
                   "Kognitif" => "proses_klinis", "Kolom Baru" => "lainnya" }, categories)
    assert_equal competency_items(:domain_komunikasi), event.assessment_dimensions.find_by!(name: "Komunikasi efektif").competency_item,
                 "dimensi yang namanya sama dengan ranah kompetensi langsung dipetakan"

    siti = event.assessment_instances.find_by!(student: @siti)
    assert_equal 72.5, siti.score.to_f
    assert_equal "scored", siti.status
    assert_equal "import", siti.source
    assert_equal exam_date, siti.scored_at.to_date
    assert_equal 4, siti.assessment_dimension_scores.count

    andi = event.assessment_instances.find_by!(student: @andi)
    assert_equal 61.5, andi.score.to_f, "koma desimal diterima, email dinormalisasi"
    assert_equal 2, andi.assessment_dimension_scores.count, "sel kosong dan \"-\" tidak menjadi nilai 0"
  end

  test "unggah ulang berkas yang sama dilewati sebagai sudah diimpor" do
    import(rows)
    again = import(rows)

    assert_equal 0, again.created_count
    assert_equal 2, again.skip_reasons["sudah_diimpor"]
    assert_equal 1, AssessmentEvent.where(external_code: "CBT-UJI-1").count
    assert_equal 2, AssessmentInstance.joins(:assessment_event).where(assessment_events: { external_code: "CBT-UJI-1" }).count
  end

  test "progress_test menjadi event Progress Test, formative menjadi CBT formatif" do
    csv = "email,exam_code,exam_type,total_score,held_at\n" \
          "siti@example.com,PT-1,progress_test,40,#{exam_date.iso8601}\n" \
          "siti@example.com,FORM-1,formative,70,#{exam_date.iso8601}\n"
    import(csv)

    assert_equal [ "progress_test", nil ], AssessmentEvent.find_by!(external_code: "PT-1").slice(:assessment_type, :exam_purpose).values
    assert_equal [ "cbt", "formative" ], AssessmentEvent.find_by!(external_code: "FORM-1").slice(:assessment_type, :exam_purpose).values
    assert_equal "PT-1", AssessmentEvent.find_by!(external_code: "PT-1").name, "tanpa exam_title, kode menjadi nama"
  end

  test "tanpa exam_code, judul dan tanggal dari formulir membentuk kode ujian" do
    csv = "email,total_score,Kognitif\nsiti@example.com,80,75\n"
    import(csv, exam_title: "Ujian Blok 3.1", exam_date: Date.new(2026, 3, 2))

    event = AssessmentEvent.find_by!(external_code: "CBT-UJIAN-BLOK-3-1-20260302")
    assert_equal "Ujian Blok 3.1", event.name
    assert_equal Date.new(2026, 3, 2), event.exam_date
  end

  test "tanggal dari judul bergaya jejak.pro: (DDMMYY)" do
    csv = "email,exam_code,exam_title,total_score\nsiti@example.com,X-1,Ujian CBT (060626),80\n"
    import(csv)
    assert_equal Date.new(2026, 6, 6), AssessmentEvent.find_by!(external_code: "X-1").exam_date
  end

  test "nilai dimensi bukan angka menggagalkan baris itu saja, tanpa sisa setengah jadi" do
    csv = HEADER +
          "siti@example.com,CBT-UJI-2,Ujian,summative,70,#{exam_date.iso8601},r1,80,abc,70,\n" \
          "andi@example.com,CBT-UJI-2,Ujian,summative,60,#{exam_date.iso8601},r2,60,60,60,\n"
    result = import(csv)

    assert_equal 1, result.created_count
    assert_equal 1, result.error_count
    assert_match "bukan angka", result.error_messages.first
    assert_not AssessmentInstance.exists?(student: @siti, assessment_event: AssessmentEvent.find_by!(external_code: "CBT-UJI-2"))
  end

  test "berkas tanpa kolom email ditolak dengan pesan" do
    result = import("nama,total_score\nSiti,80\n")
    assert_equal 1, result.error_count
    assert_match "Kolom email tidak ditemukan", result.error_messages.first
    assert_empty result.created_event_ids
  end

  test "rollback menghapus nilai & event yang dibuat, peserta terdaftar kembali Terdaftar" do
    event = AssessmentEvent.create!(name: "CBT Terjadwal", assessment_type: "cbt", academic_period: @period, max_score: 100,
                                    status: "published", external_code: "CBT-UJI-1")
    registered = AssessmentInstance.create!(assessment_event: event, student: @siti, max_score: 100)

    result = import(rows)
    assert_equal 1, result.created_count
    assert_equal 1, result.updated_count
    assert_equal [ registered.id ], result.filled_instance_ids
    assert_equal "scored", registered.reload.status

    assert result.rollback!(users(:budi))
    assert_equal "rolled_back", result.reload.status
    assert_equal "registered", registered.reload.status
    assert_nil registered.score
    assert_equal 0, registered.assessment_dimension_scores.count
    assert_not AssessmentInstance.exists?(assessment_event: event, student: @andi)
    assert AssessmentEvent.exists?(event.id), "event yang tidak dibuat unggahan ini tidak dihapus"
    assert_not result.rollbackable?
  end

  test "rollback membuang event baru yang tidak berisi nilai lain" do
    result = import(rows)
    event_id = result.created_event_ids.first

    result.rollback!(users(:budi))
    assert_not AssessmentEvent.exists?(event_id)
  end
end
