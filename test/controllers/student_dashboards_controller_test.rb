require "test_helper"

# Dasbor Mahasiswa (hanya-baca) untuk pengajar/kaprodi/admin + halaman
# asesmen yang menerima ?student_id=.
class StudentDashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  STUDENT_PAGES = %i[exam_scores_path assessments_path student_assessments_path student_feedback_journal_path
                     academic_assessments_path entrustment_decisions_path].freeze

  test "dosen membuka dasbor mahasiswa: profil, statistik, dan 6 kartu berparameter student_id" do
    sign_in users(:budi)
    siti = users(:siti)
    get student_dashboard_path(siti)
    assert_response :success
    assert_match siti.full_name, response.body
    assert_select '[data-testid="student-stats"]'

    hub = Nokogiri::HTML5(response.body).at_css('[data-testid="assessment-hub"]')
    expected = STUDENT_PAGES.map { |h| send(h, student_id: siti.id) }
    assert_equal expected, hub.css("a").map { |a| a["href"] }
  end

  test "kaprodi bisa membuka; mahasiswa lain dan pengguna non-mahasiswa ditolak" do
    sign_in users(:dedi)
    get student_dashboard_path(users(:siti))
    assert_response :success
    assert_no_match "Sunting akun", response.body

    get student_dashboard_path(users(:budi))
    assert_redirected_to search_path(q: users(:budi).email)

    sign_in users(:siti)
    get student_dashboard_path(users(:siti))
    assert_redirected_to dashboard_path
  end

  test "admin melihat tombol sunting akun" do
    users(:budi).roles << roles(:admin)
    sign_in users(:budi)
    get student_dashboard_path(users(:siti))
    assert_match "Sunting akun", response.body
  end

  test "setiap halaman asesmen menampilkan data mahasiswa yang dipilih beserta banner hanya-baca" do
    sign_in users(:budi)
    siti = users(:siti)
    STUDENT_PAGES.each do |helper|
      get send(helper, student_id: siti.id)
      assert_response :success, "#{helper} gagal"
      assert_select '[data-testid="viewing-student-banner"]', 1, "#{helper} tanpa banner"
      assert_select "a[href=?]", student_dashboard_path(siti)
    end

    get exam_scores_path(student_id: siti.id)
    assert_match assessment_events(:cbt_blok).name, response.body
    detail = student_assessment_path(assessment_instances(:siti_cbt_1), student_id: siti.id)
    assert_select "a[href=?]", detail, minimum: 1, message: "tautan detail harus membawa student_id"
    get detail
    assert_response :success
    get student_assessments_path(student_id: siti.id)
    assert_select "form[action*='register']", 0, "tombol Daftar tidak boleh tampil untuk mahasiswa lain"
  end

  test "detail percobaan mahasiswa lain bisa dilihat tanpa form pengumpulan; submit tetap milik sendiri" do
    sign_in users(:budi)
    mine = assessment_instances(:siti_cbt_1)
    get student_assessment_path(mine, student_id: users(:siti).id)
    assert_response :success
    assert_select "form[action=?]", submit_student_assessment_path(mine), 0

    patch submit_student_assessment_path(mine, student_id: users(:siti).id), params: { self_evaluation: "x" }
    assert_response :not_found
    assert_equal "scored", mine.reload.status
  end

  test "student_id diabaikan bagi mahasiswa: tetap melihat data sendiri tanpa banner" do
    sign_in users(:siti)
    get exam_scores_path(student_id: users(:budi).id)
    assert_response :success
    assert_select '[data-testid="viewing-student-banner"]', 0
    assert_match assessment_events(:cbt_blok).name, response.body
  end
end
