require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def section(testid)
    Nokogiri::HTML5(response.body).at_css(%([data-testid="#{testid}"]))
  end

  test "menolak akses tanpa login" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "semua peran melihat sapaan, kartu sponsor AIPKI, dan narasi jejak.pro" do
    %i[siti budi].each do |user|
      sign_in users(user)
      get dashboard_path

      assert_response :success
      assert_match users(user).full_name, section("welcome-header").text
      assert_match "Sponsor Pengembangan", response.body
      assert_match "Dari Essential ke jejak.pro", response.body
    end
  end

  test "dosen melihat Ringkasan Hari Ini, Perlu Tindakan, dan Akses Cepat tanpa tautan admin" do
    sign_in users(:budi) # active_role: dosen
    get dashboard_path

    assert_response :success
    assert section("faculty-action-summary")
    assert_match "Perlu Tindakan Anda", response.body
    assert_match "Mahasiswa Bimbingan Anda", response.body
    hrefs = section("faculty-quick-links").css("a").map { |a| a["href"] }
    assert_includes hrefs, clinical_cases_path(scope: "to_verify")
    assert_not_includes hrefs, admin_users_path
    assert_no_match "Pusat Asesmen", response.body
  end

  test "admin melihat tautan konfigurasi di Akses Cepat" do
    admin_user = users(:budi)
    admin_user.roles << roles(:admin)
    admin_user.update!(active_role: roles(:admin))
    sign_in admin_user

    get dashboard_path

    hrefs = section("faculty-quick-links").css("a").map { |a| a["href"] }
    assert_includes hrefs, admin_users_path
    assert_includes hrefs, admin_evaluation_schedules_path
  end

  test "dosen melihat panel Perlu Dinilai & kasus menunggu verifikasi" do
    DopsEvaluation.create!(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Draf Dashboard Test", evaluated_at: Date.current, status: "draft",
      scores: { komunikasi: 7, profesionalisme: 7, penilaian_global: 7 }
    )

    sign_in users(:budi)
    get dashboard_path

    assert_match "Draf Dashboard Test", section("pending-grading").text
    pending_cases = section("pending-case-verifications")
    assert_match "Nyeri perut kanan bawah", pending_cases.text
    assert pending_cases.at_css(%(a[href="#{clinical_cases_path(scope: 'to_verify')}"]))
  end

  test "dosen melihat mahasiswa bimbingan per peran: preseptor, tutor, pembimbing tugas akhir" do
    sign_in users(:budi)
    get dashboard_path

    %w[preceptor-mentees tutor-mentees final-project-mentees].each do |testid|
      assert_match "Siti Mahasiswa", section(testid).text, testid
    end
    assert_match "Ilmu Penyakit Dalam", section("preceptor-mentees").text
    assert_match "Sistem Kardiovaskular", section("tutor-mentees").text
  end

  test "preseptor tanpa rotasi berjalan melihat keadaan kosong modul preseptor" do
    clinical_rotations(:wati_preceptored_rotation).update_columns(start_date: 40.days.ago.to_date, end_date: 20.days.ago.to_date)

    sign_in users(:wati)
    get dashboard_path

    assert_match "Tidak sedang mem-preseptori rotasi klinis saat ini.", response.body
  end

  test "rekomendasi remediasi menandai mahasiswa di beranda pembimbing dan mahasiswa itu sendiri" do
    clinical_cases(:submitted_case_siti).update_columns(status: "verified", recommend_remediation: true,
                                                        verified_by_id: users(:budi).id, verified_at: 1.day.ago)

    sign_in users(:budi)
    get dashboard_path
    attention = section("attention-students")
    assert_match "Siti Mahasiswa", attention.text
    assert_match "Rekomendasi remediasi", attention.text

    sign_in users(:siti)
    get dashboard_path
    assert_match "Rekomendasi remediasi", section("academic-flags").text
  end

  test "kaprodi tidak melihat tile verifikasi, tetapi melihat mahasiswa prodinya yang perlu perhatian" do
    clinical_cases(:submitted_case_siti).update_columns(status: "verified", recommend_remediation: true, verified_at: 1.day.ago)

    sign_in users(:dedi) # kaprodi prodi Sarjana Kedokteran, sama dengan Siti
    get dashboard_path

    assert_no_match "Kasus Perlu Diverifikasi", section("faculty-action-summary").text
    assert_match "Siti Mahasiswa", section("attention-students").text
  end

  test "tanpa antrean apa pun, beranda pengajar menampilkan keadaan semua beres" do
    ClinicalCase.update_all(status: "verified")
    ActivityLog.update_all(verified_at: Time.current)
    clinical_rotations(:wati_preceptored_rotation).update_columns(start_date: Date.current, end_date: 20.days.from_now.to_date)

    sign_in users(:wati)
    get dashboard_path

    assert section("all-clear")
    assert_match "Tidak ada yang menunggu Anda saat ini", response.body
  end

  test "jadwal evaluasi prodi tampil sampai penilai mengirim penilaian sejenis" do
    rotation = clinical_rotations(:wati_preceptored_rotation)
    EvaluationSchedule.create!(student: users(:siti), evaluator: users(:wati), clinical_rotation: rotation,
                               kind: "dops", scheduled_at: Time.current.beginning_of_day + 9.hours, topic: "Jahit luka")

    sign_in users(:wati)
    get dashboard_path
    assert_match "Siti Mahasiswa", section("scheduled-evaluations").text

    DopsEvaluation.create!(student: users(:siti), evaluator: users(:wati), clinical_rotation: rotation,
                           procedure_name: "Jahit luka", evaluated_at: Date.current, status: "submitted",
                           scores: { komunikasi: 7, profesionalisme: 7, penilaian_global: 7 })
    get dashboard_path
    assert_nil section("scheduled-evaluations")
  end

  test "agenda mendatang memuat rotasi yang akan berakhir untuk mahasiswa dan preseptornya" do
    clinical_rotations(:ongoing_rotation_siti).update_columns(end_date: 3.days.from_now.to_date)

    sign_in users(:siti)
    get dashboard_path
    agenda = section("upcoming-agenda")
    assert_match "Rotasi Klinik — Ilmu Penyakit Dalam", agenda.text
    assert_match "Akan Berakhir", agenda.text
    assert_match "3 hari lagi", agenda.text

    sign_in users(:budi)
    get dashboard_path
    assert_match "Siti Mahasiswa", section("upcoming-agenda").text
  end

  test "mahasiswa melihat peringatan kasus draft dan kasus yang diminta diperbaiki" do
    clinical_cases(:submitted_case_siti).update_columns(status: "needs_revision", verified_by_id: users(:budi).id)

    sign_in users(:siti)
    get dashboard_path

    assert_match "1 kasus klinis masih berupa draft", section("draft-case-alert").text
    revision = section("revision-case-alert")
    assert_match "1 kasus klinis diminta diperbaiki", revision.text
    assert_match "Budi Dosen", revision.text
  end

  test "mahasiswa melihat fokus rotasi berjalan dan kelengkapan profil" do
    sign_in users(:siti)
    get dashboard_path

    focus = section("student-focus")
    assert_match "Rotasi Berjalan", focus.text
    assert_match "Ilmu Penyakit Dalam", focus.text
    assert_match "#{users(:siti).profile_completeness}%", section("profile-completeness").text
  end

  test "mahasiswa dengan evaluasi submitted melihat peta kompetensi sendiri" do
    sign_in users(:siti)
    get dashboard_path

    assert_match "Peta Kompetensi DOPS Anda", response.body
    assert_match "Peta Kompetensi Mini-CEX Anda", response.body
  end

  test "mahasiswa berotasi tanpa kasus baru 2 hari melihat pengingat pencatatan kasus" do
    siti = users(:siti)
    siti.clinical_rotations.ongoing.update_all(start_date: 10.days.ago.to_date)
    siti.clinical_cases.update_all(created_at: 5.days.ago)
    sign_in siti

    get dashboard_path

    assert_match "hari tidak ada kasus baru yang Anda catat", response.body
  end

  test "pengingat hilang setelah mahasiswa mencatat kasus hari ini" do
    siti = users(:siti)
    siti.clinical_rotations.ongoing.update_all(start_date: 10.days.ago.to_date)
    siti.clinical_cases.create!(case_date: Date.current, chief_complaint: "Batuk pilek")
    sign_in siti

    get dashboard_path

    assert_no_match "tidak ada kasus baru yang Anda catat", response.body
  end

  test "mahasiswa yang baru mulai rotasi hari ini belum ditagih kasus" do
    siti = users(:siti)
    siti.clinical_rotations.ongoing.update_all(start_date: Date.current)
    siti.clinical_cases.delete_all
    sign_in siti

    get dashboard_path

    assert_no_match "Belum ada satu pun kasus", response.body
  end

  test "mahasiswa melihat Pusat Asesmen & Capaian dengan 6 kartu pintasan; dosen tidak" do
    sign_in users(:siti)
    get dashboard_path
    assert_response :success
    assert_match "Pusat Asesmen &amp; Capaian", response.body

    hub = section("assessment-hub")
    hrefs = hub.css("a").map { |a| a["href"] }
    assert_equal [ exam_scores_path, assessments_path, student_assessments_path, student_feedback_journal_path,
                   academic_assessments_path, entrustment_decisions_path ], hrefs
    assert_match "menunggu", hub.text if users(:siti).assessment_instances.awaiting_score.exists?

    sign_in users(:budi)
    get dashboard_path
    assert_no_match "Pusat Asesmen", response.body
  end
end
