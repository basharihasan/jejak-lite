require "test_helper"

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak boleh mengakses" do
    sign_in users(:siti)
    get analytics_path
    assert_response :redirect
  end

  test "dosen melihat mahasiswa bimbingan (evaluator DOPS/Mini-CEX) tapi bukan bagian preseptor/prodi" do
    sign_in users(:budi)
    get analytics_path
    assert_response :success
    assert_match users(:siti).full_name, response.body
    assert_no_match "Mahasiswa di Wahana Anda", response.body
    assert_no_match "Program Studi", response.body
  end

  test "preseptor melihat mahasiswa di rotasi yang dibimbingnya" do
    sign_in users(:wati)
    get analytics_path
    assert_response :success
    assert_match clinical_rotations(:wati_preceptored_rotation).station_name, response.body
    assert_no_match "Mahasiswa Bimbingan", response.body
  end

  test "kaprodi hanya melihat mahasiswa program studinya sendiri, tanpa pilihan pindah prodi" do
    sign_in users(:dedi)
    get analytics_path
    assert_response :success
    assert_match users(:siti).full_name, response.body
    assert_no_match 'name="study_program_id"', response.body
  end

  test "admin melihat ketiga bagian sekaligus" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    get analytics_path
    assert_response :success
    assert_match "Mahasiswa Bimbingan", response.body
    assert_match "Mahasiswa di Wahana Anda", response.body
    assert_match "Program Studi", response.body
  end

  test "mahasiswa berisiko (skor rendah) diurutkan lebih dulu daripada yang skornya tinggi" do
    DopsEvaluation.create!(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Kasus Risiko Rendah", evaluated_at: Date.current,
      scores: { komunikasi: 2, profesionalisme: 2, penilaian_global: 2 }
    )
    mahasiswa_pintar = User.create!(full_name: "Mahasiswa Nilai Tinggi", email: "pintar@example.com", password: "password123", confirmed_at: Time.current)
    mahasiswa_pintar.roles << roles(:mahasiswa)
    rotasi_pintar = ClinicalRotation.create!(user: mahasiswa_pintar, academic_period: academic_periods(:current_period), station_name: "Bedah", start_date: 1.day.ago, end_date: 10.days.from_now)
    DopsEvaluation.create!(
      student: mahasiswa_pintar, evaluator: users(:budi), clinical_rotation: rotasi_pintar,
      procedure_name: "Kasus Nilai Tinggi", evaluated_at: Date.current,
      scores: { komunikasi: 9, profesionalisme: 9, penilaian_global: 9 }
    )

    sign_in users(:budi)
    get analytics_path

    body = response.body
    assert_operator body.index(users(:siti).full_name), :<, body.index(mahasiswa_pintar.full_name),
      "mahasiswa dengan skor rendah (lebih berisiko) harus muncul lebih dulu"
  end

  test "filter periode akademik menyaring skor DOPS/Mini-CEX ke satu periode" do
    # siti tetap muncul di daftar bimbingan (tugas akhir bukan data per-periode),
    # tapi rata-rata DOPS/Mini-CEX-nya harus kosong karena rotasinya ada di
    # current_period, bukan periode lain ini.
    periode_lain = AcademicPeriod.create!(name: "Periode Lampau", start_date: 2.years.ago.to_date, end_date: 1.year.ago.to_date)

    sign_in users(:budi)
    get analytics_path(academic_period_id: periode_lain.id)

    assert_response :success
    # Dibatasi ke <main>: cangkang layout memuat kelas Tailwind seperti
    # bg-white/95 yang ikut cocok dengan pola "/9".
    main_text = css_select("main").text
    assert_match users(:siti).full_name, main_text
    assert_no_match "/9", main_text
  end
end
