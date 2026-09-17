require "test_helper"

# Fase 25 — Pilar B: Assessment Event, percobaan berulang, impor CSV
# berpemetaan kolom, pengumpulan mahasiswa, lembar penguji, CBD dari kasus,
# Evaluasi Akademik, jurnal umpan balik, jadwal WBA, Peta EPA.
class AssessmentPipelineTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
  end

  # ── Admin & impor ──
  test "admin membuat event dan mengimpor nilai CSV dengan pemetaan kolom, termasuk percobaan ke-2" do
    sign_in @admin
    event = assessment_events(:cbt_blok)

    get import_admin_assessment_event_path(event)
    assert_response :success

    csv = "Email Mahasiswa;Nilai Akhir;Ujian Ke\nsiti@example.com;78,5;2\ntidakada@example.com;50;1\n"
    post import_preview_admin_assessment_event_path(event), params: { file: Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "n.csv") }
    assert_response :success
    assert_select "select[name='mapping[email]'] option[selected][value='Email Mahasiswa']"
    assert_select "select[name='mapping[score]'] option[selected][value='Nilai Akhir']"

    assert_difference "AssessmentInstance.count", 1 do
      post import_create_admin_assessment_event_path(event), params: { csv_text: csv, mapping: { email: "Email Mahasiswa", score: "Nilai Akhir", attempt: "Ujian Ke" } }
    end
    assert_response :success
    assert_match "1 nilai baru", response.body
    assert_match "tidakada@example.com", response.body

    second = AssessmentInstance.find_by!(assessment_event: event, student: users(:siti), attempt_number: 2)
    assert_equal 78.5, second.score.to_f
    assert_equal "import", second.source
    assert_equal second, AssessmentInstance.representative_for(event, users(:siti)) # nilai tertinggi mewakili
  end

  test "impor ke event sekali-jalan menimpa percobaan 1" do
    sign_in @admin
    event = assessment_events(:cbt_blok)
    event.update!(allow_multiple_attempts: false)
    assert_no_difference "AssessmentInstance.count" do
      post import_create_admin_assessment_event_path(event), params: { csv_text: "email,score\nsiti@example.com,90\n", mapping: { email: "email", score: "score" } }
    end
    assert_equal 90, assessment_instances(:siti_cbt_1).reload.score.to_f
  end

  test "templat CSV berisi daftar mahasiswa event dan headernya langsung terpetakan" do
    sign_in @admin
    event = assessment_events(:cbt_blok)

    get import_admin_assessment_event_path(event)
    assert_select "a[href=?]", import_template_admin_assessment_event_path(event, format: :csv)

    get import_template_admin_assessment_event_path(event, format: :csv)
    assert_response :success
    assert_match "text/csv", response.media_type
    assert_match "attachment", response.headers["Content-Disposition"]

    rows = CSV.parse(response.body.delete_prefix("\uFEFF"))
    assert_equal %w[email nama_mahasiswa npm skor percobaan tanggal], rows.first
    assert_includes rows.map(&:first), users(:siti).email
    assert rows.drop(1).all? { |r| r[3].nil? }, "kolom nilai templat harus kosong"
    assert rows.drop(1).all? { |r| r[5] == event.exam_date.iso8601 }, "tanggal bawaan = tanggal ujian event"

    post import_preview_admin_assessment_event_path(event),
         params: { file: Rack::Test::UploadedFile.new(StringIO.new(response.body), "text/csv", original_filename: "t.csv") }
    assert_select "select[name='mapping[email]'] option[selected][value='email']"
    assert_select "select[name='mapping[score]'] option[selected][value='skor']"
    assert_select "select[name='mapping[attempt]'] option[selected][value='percobaan']"
    assert_select "select[name='mapping[date]'] option[selected][value='tanggal']"
    assert_select "input[name='create_dimensions[]'][value='nama_mahasiswa']", 0
    assert_select "input[name='create_dimensions[]'][value='npm']", 0
  end

  test "templat event berdimensi memuat kolom per dimensi, tanpa kolom skor total" do
    sign_in @admin
    event = assessment_events(:cbt_blok)
    event.update!(allow_multiple_attempts: false)
    event.assessment_dimensions.create!(name: "Penalaran Klinis", max_score: 100)

    get import_template_admin_assessment_event_path(event, format: :csv)
    assert_equal %w[email nama_mahasiswa npm tanggal Penalaran\ Klinis], CSV.parse(response.body.delete_prefix("\uFEFF")).first
  end

  test "baris tanpa nilai dilewati dan tidak menimpa nilai yang sudah ada" do
    sign_in @admin
    event = assessment_events(:cbt_blok)
    event.update!(allow_multiple_attempts: false)
    before = assessment_instances(:siti_cbt_1).score

    assert_no_difference "AssessmentInstance.count" do
      post import_create_admin_assessment_event_path(event),
           params: { csv_text: "email,nama_mahasiswa,skor\nsiti@example.com,Siti,\n", mapping: { email: "email", score: "skor" } }
    end
    assert_equal before, assessment_instances(:siti_cbt_1).reload.score
    assert_match "1 baris tanpa nilai dilewati", response.body
  end

  test "kolom tanggal mengisi tanggal nilai per baris; kosong = tanggal ujian event; format salah ditolak" do
    sign_in @admin
    event = assessment_events(:cbt_blok)
    csv = "email,skor,percobaan,tanggal\nsiti@example.com,70,2,20/09/2026\nsiti@example.com,75,3,\nsiti@example.com,80,4,kemarin\n"

    assert_difference "AssessmentInstance.count", 2 do
      post import_create_admin_assessment_event_path(event),
           params: { csv_text: csv, mapping: { email: "email", score: "skor", attempt: "percobaan", date: "tanggal" } }
    end
    siti = users(:siti)
    assert_equal Date.new(2026, 9, 20), AssessmentInstance.find_by!(assessment_event: event, student: siti, attempt_number: 2).scored_at.to_date
    assert_equal event.exam_date, AssessmentInstance.find_by!(assessment_event: event, student: siti, attempt_number: 3).scored_at.to_date
    assert_nil AssessmentInstance.find_by(assessment_event: event, student: siti, attempt_number: 4)
    assert_match "tanggal &quot;kemarin&quot; tidak dikenali", response.body
  end

  test "impor tanpa pemetaan email/skor ditolak dengan pesan" do
    sign_in @admin
    post import_create_admin_assessment_event_path(assessment_events(:cbt_blok)), params: { csv_text: "a,b\n1,2\n", mapping: { email: "", score: "" } }
    assert_match "wajib dipetakan", response.body
  end

  test "admin mendaftarkan percobaan & mengisi nilai manual; event sekali-jalan menolak pendaftaran ganda" do
    sign_in @admin
    event = assessment_events(:soca_kardio)
    assert_difference "AssessmentInstance.count", 1 do
      post add_instance_admin_assessment_event_path(event), params: { student_id: users(:siti).id, examiner_id: users(:budi).id }
    end
    instance = AssessmentInstance.last
    assert_no_difference "AssessmentInstance.count" do
      post add_instance_admin_assessment_event_path(event), params: { student_id: users(:siti).id }
    end
    patch admin_assessment_instance_path(instance), params: { assessment_instance: { score: 85 } }
    assert_equal "scored", instance.reload.status
    assert_equal 85, instance.score.to_f
  end

  test "halaman asesmen mahasiswa menampilkan radar dimensi dan posisi kohort" do
    event = assessment_events(:cbt_blok)
    event.update!(allow_multiple_attempts: false)
    dim = event.assessment_dimensions.create!(name: "Penalaran Klinis", max_score: 100)
    mine = assessment_instances(:siti_cbt_1)
    AssessmentDimensionScore.create!(assessment_instance: mine, assessment_dimension: dim, score: 62)

    sign_in users(:siti)
    get student_assessment_path(mine)
    assert_response :success
    assert_select '[data-testid="dimension-profile"]'
    assert_select '[data-testid="cohort-position"]', 0 # kohort baru 1 orang

    2.times do |i|
      u = User.create!(full_name: "Kohort #{i}", email: "kohort#{i}@example.com", password: "password123", confirmed_at: Time.current)
      AssessmentInstance.create!(assessment_event: event, student: u, attempt_number: 1, status: "scored", source: "import",
                                 score: 70 + i * 10, max_score: 100, scored_at: Time.current)
    end
    get student_assessment_path(mine)
    assert_select '[data-testid="cohort-position"]'
    assert_match "Persentil", response.body
    assert_match "Rerata Kohort", response.body
  end

  test "baris Evaluasi Akademik menaut ke detail percobaan dan memuat lencana persentil bila kohort cukup" do
    event = assessment_events(:cbt_blok)
    mine = assessment_instances(:siti_cbt_1)
    sign_in users(:siti)

    get exam_scores_path
    assert_select "a[href=?]", student_assessment_path(mine), text: /Detail & radar/
    assert_no_match "Persentil", response.body

    2.times do |i|
      u = User.create!(full_name: "Kohort #{i}", email: "kohort#{i}@example.com", password: "password123", confirmed_at: Time.current)
      AssessmentInstance.create!(assessment_event: event, student: u, attempt_number: 1, status: "scored", source: "import",
                                 score: 70 + i * 10, max_score: 100, scored_at: Time.current)
    end
    get exam_scores_path
    assert_match "Persentil", response.body
    assert_match "3 peserta", response.body
  end

  test "bukan admin tidak bisa membuka Assessment Events" do
    sign_in users(:siti)
    get admin_assessment_events_path
    assert_redirected_to dashboard_path
  end

  # ── Mahasiswa ──
  test "mahasiswa melihat event yang cocok prodi & bloknya, mendaftar, mengumpulkan, lalu dinilai penguji" do
    sign_in users(:siti) # PSSK, enrolment Sistem Kardiovaskular aktif (fixture)
    get student_assessments_path
    assert_response :success
    assert_match "SOCA Sistem Kardiovaskular", response.body
    assert_no_match "Event Draf", response.body

    assert_difference "AssessmentInstance.count", 1 do
      post register_student_assessment_event_path(assessment_events(:soca_kardio))
    end
    instance = AssessmentInstance.last
    assert_redirected_to student_assessment_path(instance)

    patch submit_student_assessment_path(instance), params: { self_evaluation: "Sudah paham patofisiologi, perlu latihan tatalaksana." }
    assert_equal "submitted", instance.reload.status

    # Penguji (belum bertugas) mengambil dan menilai
    sign_in users(:budi)
    get examiner_evaluations_path
    assert_response :success
    assert_match users(:siti).full_name, response.body

    patch examiner_evaluation_path(instance), params: { assessment_instance: { score: 82, feedback_keep: "Anamnesis runtut.", feedback_improve: "Rencana tatalaksana perlu lebih spesifik." } }
    assert_redirected_to examiner_evaluations_path
    instance.reload
    assert_equal "scored", instance.status
    assert_equal users(:budi), instance.examiner
    assert Notification.exists?(recipient: users(:siti), notifiable: instance)

    # Mahasiswa melihat nilai, jurnal umpan balik, dan evaluasi akademik
    sign_in users(:siti)
    get student_assessment_path(instance)
    assert_match "Rencana tatalaksana perlu lebih spesifik", response.body
    get student_feedback_journal_path
    assert_match "Anamnesis runtut", response.body
    get exam_scores_path
    assert_response :success
    assert_match "SOCA / MSP", response.body
    assert_match "Ujian Tulis / CBT", response.body
  end

  test "mahasiswa tanpa enrolment blok tidak melihat event berblok; prodi lain tidak melihat event prodi" do
    tutorial_enrollments(:siti_kardio).update!(active: false)
    sign_in users(:siti)
    get student_assessments_path
    assert_no_match "SOCA Sistem Kardiovaskular", response.body

    users(:siti).update!(study_program: study_programs(:profesi_dokter))
    tutorial_enrollments(:siti_kardio).update!(active: true)
    get student_assessments_path
    assert_no_match "SOCA Sistem Kardiovaskular", response.body
  end

  test "mahasiswa tidak bisa mendaftar event impor atau event draf" do
    sign_in users(:siti)
    assert_no_difference "AssessmentInstance.count" do
      post register_student_assessment_event_path(assessment_events(:cbt_blok))
      post register_student_assessment_event_path(assessment_events(:draft_event))
    end
  end

  test "nilai melebihi maksimum ditolak" do
    instance = assessment_instances(:siti_cbt_1)
    instance.score = 120
    assert_not instance.valid?
  end

  # ── CBD dari kasus ──
  test "CBD diinisiasi dari kasus yang sudah diajukan, penguji terisi dari verifier" do
    kasus = clinical_cases(:submitted_case_siti)
    kasus.update!(status: "verified", verified_by: users(:budi), verified_at: Time.current)
    sign_in users(:siti)

    get clinical_case_path(kasus)
    assert_match "Inisiasi", response.body
    assert_difference "AssessmentInstance.count", 1 do
      post initiate_assessment_clinical_case_path(kasus), params: { assessment_event_id: assessment_events(:cbd_ipd).id }
    end
    instance = AssessmentInstance.last
    assert_equal kasus, instance.clinical_case
    assert_equal users(:budi), instance.examiner
    assert_equal "submitted", instance.status

    # Tidak bisa dua kali ke event yang sama
    assert_no_difference "AssessmentInstance.count" do
      post initiate_assessment_clinical_case_path(kasus), params: { assessment_event_id: assessment_events(:cbd_ipd).id }
    end
  end

  test "CBD tidak bisa diinisiasi dari draf atau kasus orang lain" do
    sign_in users(:siti)
    assert_no_difference "AssessmentInstance.count" do
      post initiate_assessment_clinical_case_path(clinical_cases(:draft_case_siti)), params: { assessment_event_id: assessment_events(:cbd_ipd).id }
    end
    assert_response :redirect
  end

  # ── Jadwal WBA ──
  test "admin membuat jadwal Mini-CEX; mahasiswa & penilai diberi notifikasi dan melihatnya di beranda" do
    sign_in @admin
    assert_difference "EvaluationSchedule.count", 1 do
      post admin_evaluation_schedules_path, params: { evaluation_schedule: {
        kind: "mini_cex", student_id: users(:siti).id, evaluator_id: users(:wati).id, scheduled_at: 2.days.from_now, topic: "Nyeri dada"
      } }
    end
    assert Notification.where(recipient: users(:siti)).where("title LIKE ?", "%Jadwal Mini-CEX%").exists?
    assert Notification.where(recipient: users(:wati)).where("title LIKE ?", "%Jadwal Mini-CEX%").exists?

    sign_in users(:wati)
    get dashboard_path
    assert_match "Jadwal DOPS / Mini-CEX Mendatang", response.body
    assert_match "Nyeri dada", response.body
  end

  # ── Peta EPA ──
  test "verifikasi kasus dengan ranah EPA terpilih menulis level entrustment; penilaian baru menggantikan yang lama" do
    kasus = clinical_cases(:submitted_case_siti)
    epa = competency_frameworks(:skdi_ringkas).domains.first
    sign_in users(:budi)

    assert_difference "EntrustmentDecision.count", 1 do
      patch verify_clinical_case_path(kasus), params: { entrustment_level: "supervisi_tidak_langsung", epa_item_ids: [ epa.id ], comment: "Baik" }
    end
    first = EntrustmentDecision.current.find_by!(student: users(:siti), competency_item: epa)
    assert_equal 3, first.level
    assert_equal kasus, first.clinical_case

    post entrustment_decisions_path, params: { student_id: users(:siti).id, competency_item_id: epa.id, level: 4, justification: "Sudah mandiri di tiga kasus terakhir." }
    assert_redirected_to entrustment_decisions_path(student_id: users(:siti).id)
    assert_not_nil first.reload.superseded_at
    assert_equal 4, EntrustmentDecision.current.find_by!(student: users(:siti), competency_item: epa).level

    get entrustment_decisions_path(student_id: users(:siti).id)
    assert_response :success
    assert_match "tergantikan", response.body
  end

  test "mahasiswa melihat Peta EPA miliknya tanpa form; pengajar tanpa relasi ditolak menilai" do
    sign_in users(:siti)
    get entrustment_decisions_path
    assert_response :success
    assert_no_match "Isi Penilaian", response.body

    stranger = User.create!(full_name: "Dosen Asing", email: "asing@example.com", password: "password123", confirmed_at: Time.current)
    stranger.roles << roles(:dosen)
    sign_in stranger
    assert_no_difference "EntrustmentDecision.count" do
      post entrustment_decisions_path, params: { student_id: users(:siti).id, competency_item_id: competency_frameworks(:skdi_ringkas).domains.first.id, level: 5, justification: "Coba-coba menilai tanpa relasi" }
    end
  end

  test "Peta Kompetensi periode ini membaca nilai dari AssessmentInstance" do
    sign_in users(:siti)
    get academic_assessments_path
    assert_response :success
    assert_match "CBT Blok Kardiovaskular", response.body
  end
end
