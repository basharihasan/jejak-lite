require "test_helper"

# Kesesuaian akses fitur dengan peran: menu yang ditawarkan sama dengan yang
# diizinkan, kaprodi terikat ke prodi binaannya, dan tak seorang pun menilai
# atau memverifikasi miliknya sendiri (akun multi-peran).
class RoleAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def create_student(name, program)
    User.create!(full_name: name, email: "#{name.parameterize}@example.com", password: "password123",
                 confirmed_at: Time.current, study_program: study_programs(program)).tap do |user|
      user.roles << roles(:mahasiswa)
    end
  end

  def make_admin(user)
    user.roles << roles(:admin)
    user
  end

  # ── Menu ────────────────────────────────────────────────────────────────

  test "kaprodi tidak ditawari Validasi Kasus/Kegiatan, tetapi ditawari Jadwal & Learning Unit" do
    sign_in users(:dedi)
    get dashboard_path

    assert_select "aside#sidebar" do
      assert_select "p", text: "Coaching Center"
      assert_select "a[href=?]", clinical_cases_path(scope: "to_verify"), 0
      assert_select "a[href=?]", activity_logs_path(scope: "to_verify"), 0
      assert_select "a[href=?]", new_admin_student_relabel_path
      assert_select "a[href=?]", admin_evaluation_schedules_path
      assert_select "a[href=?]", admin_learning_units_path
    end
    assert_select ".mobile-bottom-nav a[href=?]", clinical_cases_path(scope: "to_verify"), 0
    assert_select ".mobile-bottom-nav a[href=?]", assessments_path
  end

  test "dosen tidak ditawari menu pengelolaan prodi" do
    sign_in users(:budi)
    get dashboard_path

    assert_select "aside#sidebar a[href=?]", clinical_cases_path(scope: "to_verify")
    assert_select "aside#sidebar a[href=?]", admin_evaluation_schedules_path, 0
    assert_select "aside#sidebar a[href=?]", admin_learning_units_path, 0
  end

  # ── Kaprodi terikat prodi binaan ────────────────────────────────────────

  test "kaprodi hanya membuka halaman mahasiswa prodi binaannya; dosen boleh lintas prodi" do
    pspd = create_student("Rani Profesi", :profesi_dokter)

    sign_in users(:dedi) # kaprodi PSSK
    get student_dashboard_path(pspd)
    assert_redirected_to search_path

    get exam_scores_path(student_id: pspd.id)
    assert_response :success
    assert_select '[data-testid="viewing-student-banner"]', 0

    get entrustment_decisions_path(student_id: pspd.id)
    assert_no_match pspd.full_name, response.body

    get search_path, params: { q: "rani" }
    assert_select "a[href=?]", student_dashboard_path(pspd), 0

    sign_in users(:budi)
    get student_dashboard_path(pspd)
    assert_response :success
  end

  test "jadwal DOPS & Mini-CEX kaprodi hanya untuk mahasiswa prodinya" do
    pspd = create_student("Rani Profesi", :profesi_dokter)
    other = EvaluationSchedule.create!(kind: "dops", student: pspd, scheduled_at: 2.days.from_now)
    own = EvaluationSchedule.create!(kind: "mini_cex", student: users(:siti), scheduled_at: 3.days.from_now, topic: "Anamnesis")

    sign_in users(:dedi)
    get admin_evaluation_schedules_path
    assert_response :success
    assert_select "a[href=?]", edit_admin_evaluation_schedule_path(own)
    assert_select "a[href=?]", edit_admin_evaluation_schedule_path(other), 0

    get edit_admin_evaluation_schedule_path(other)
    assert_response :not_found

    assert_no_difference "EvaluationSchedule.count" do
      post admin_evaluation_schedules_path, params: { evaluation_schedule: { kind: "dops", student_id: pspd.id, scheduled_at: 1.day.from_now } }
    end
    assert_response :unprocessable_entity
    assert_match "di luar program studi binaan Anda", response.body

    assert_difference "EvaluationSchedule.count", 1 do
      post admin_evaluation_schedules_path, params: { evaluation_schedule: { kind: "dops", student_id: users(:siti).id, scheduled_at: 1.day.from_now } }
    end
  end

  test "Learning Unit kaprodi terkunci ke prodinya" do
    pspd_unit = LearningUnit.create!(name: "Stase Bedah", study_program: study_programs(:profesi_dokter))

    sign_in users(:dedi)
    get admin_learning_units_path
    assert_no_match "Stase Bedah", response.body

    get admin_learning_unit_path(pspd_unit)
    assert_response :not_found

    post admin_learning_units_path, params: { learning_unit: { name: "Blok Baru", study_program_id: study_programs(:profesi_dokter).id } }
    assert_equal study_programs(:sarjana_kedokteran), LearningUnit.find_by!(name: "Blok Baru").study_program
  end

  test "kaprodi tanpa prodi binaan ditolak dari Jadwal & Learning Unit" do
    users(:dedi).update!(study_program: nil)
    sign_in users(:dedi)

    get admin_evaluation_schedules_path
    assert_redirected_to dashboard_path
    get admin_learning_units_path
    assert_redirected_to dashboard_path
  end

  # ── Pencarian ───────────────────────────────────────────────────────────

  test "mahasiswa menemukan pengajar lewat pencarian, tetapi tidak sesama mahasiswa" do
    create_student("Rani Sarjana", :sarjana_kedokteran)

    sign_in users(:siti)
    get search_path, params: { q: "rani" }
    assert_no_match "Rani Sarjana", response.body
    get search_path, params: { q: "wati" }
    assert_match users(:wati).full_name, response.body

    sign_in users(:budi)
    get search_path, params: { q: "rani" }
    assert_match "Rani Sarjana", response.body
  end

  # ── Verifikasi & penilaian ──────────────────────────────────────────────

  test "draf kasus hanya terbuka bagi pemilik dan admin" do
    draft = clinical_cases(:draft_case_siti)

    sign_in users(:budi)
    get clinical_case_path(draft)
    assert_redirected_to root_path
    get clinical_case_path(clinical_cases(:submitted_case_siti))
    assert_response :success

    sign_in make_admin(users(:wati))
    get clinical_case_path(draft)
    assert_response :success
  end

  test "antrean Validasi Kegiatan tidak memuat kegiatan milik sendiri" do
    sign_in users(:budi) # pemilik Jaga IGD
    get activity_logs_path(scope: "to_verify")
    assert_response :success
    assert_no_match activity_logs(:jaga_igd).title, response.body
    assert_match activity_logs(:kegiatan_siti).title, response.body
  end

  test "nilai CBT hasil impor tidak dapat ditimpa dari Lembar Penguji" do
    imported = assessment_instances(:siti_cbt_1)

    sign_in users(:budi)
    get examiner_evaluation_path(imported)
    assert_select '[data-testid="score-locked"]'

    patch examiner_evaluation_path(imported), params: { assessment_instance: { score: 99 } }
    assert_redirected_to examiner_evaluations_path
    assert_equal 62, imported.reload.score.to_i
    assert_equal "import", imported.source
  end

  test "penguji multi-peran tidak mengambil atau menilai percobaannya sendiri" do
    budi = users(:budi)
    budi.roles << roles(:mahasiswa)
    own = budi.assessment_instances.create!(assessment_event: assessment_events(:soca_kardio), attempt_number: 1,
                                             max_score: 100, status: "submitted", submitted_at: Time.current)

    sign_in budi
    get examiner_evaluations_path
    assert_select "a[href=?]", examiner_evaluation_path(own), 0

    patch examiner_evaluation_path(own), params: { assessment_instance: { score: 90 } }
    assert_equal "submitted", own.reload.status
  end

  test "mahasiswa tidak mengumpulkan dokumen ke ujian impor" do
    instance = users(:siti).assessment_instances.create!(assessment_event: assessment_events(:cbt_blok), attempt_number: 2, max_score: 100)

    sign_in users(:siti)
    patch submit_student_assessment_path(instance), params: { self_evaluation: "x" }
    assert_redirected_to student_assessment_path(instance)
    assert_equal "registered", instance.reload.status
  end

  test "akun multi-peran tidak memberi skor tugas akhirnya sendiri" do
    budi = users(:budi)
    budi.roles << roles(:mahasiswa)
    own = budi.final_projects.create!(title: "Tugas Akhir Budi", status: "proposal")

    sign_in budi
    get new_final_project_examiner_score_path(own)
    assert_redirected_to root_path
    assert FinalProjectPolicy.new(budi, final_projects(:skripsi_siti)).score?
  end
end
