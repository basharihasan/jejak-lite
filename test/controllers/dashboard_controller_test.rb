require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "menu langkah berikutnya menyesuaikan peran aktif" do
    sign_in users(:budi) # active_role: dosen

    get dashboard_path

    assert_response :success
    assert_match "Lengkapi profil", response.body
    assert_no_match "Cari pengguna", response.body # kartu khusus admin
  end

  test "peran admin melihat kartu cari pengguna" do
    admin_user = users(:budi)
    admin_user.roles << roles(:admin)
    admin_user.update!(active_role: roles(:admin))
    sign_in admin_user

    get dashboard_path

    assert_match "Cari pengguna", response.body
  end

  test "dosen melihat kartu jumlah evaluasi draf & kasus menunggu verifikasi" do
    DopsEvaluation.create!(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Draf Dashboard Test", evaluated_at: Date.current, status: "draft",
      scores: { komunikasi: 7, profesionalisme: 7, penilaian_global: 7 }
    )

    sign_in users(:budi)
    get dashboard_path

    assert_match "Evaluasi Draf Belum Dikirim", response.body
    assert_match "Kasus Klinis Menunggu Verifikasi", response.body
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

    hub = Nokogiri::HTML5(response.body).at_css('[data-testid="assessment-hub"]')
    hrefs = hub.css("a").map { |a| a["href"] }
    assert_equal [ exam_scores_path, assessments_path, student_assessments_path, student_feedback_journal_path,
                   academic_assessments_path, entrustment_decisions_path ], hrefs
    assert_match "menunggu", hub.text if users(:siti).assessment_instances.awaiting_score.exists?

    sign_in users(:budi)
    get dashboard_path
    assert_no_match "Pusat Asesmen", response.body
  end
end
