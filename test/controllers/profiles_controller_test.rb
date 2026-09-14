require "test_helper"

# Profil: biodata pribadi + cabang Akademik (mahasiswa) / Kepegawaian
# (dosen & peran lain), serta pengingat kelengkapan.
class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get profile_path
    assert_redirected_to new_user_session_path
    get edit_profile_path
    assert_redirected_to new_user_session_path
  end

  test "mahasiswa melihat cabang Akademik, bukan Kepegawaian" do
    sign_in users(:siti)
    get edit_profile_path

    assert_response :success
    assert_select "h2", text: "Akademik"
    assert_select "h2", text: "Informasi Kepegawaian", count: 0
    assert_select "label", text: "NPM / NIM"
    assert_select "select[name=?]", "user[study_program_id]"
    assert_select "input[name=?]", "user[cohort_year]"
  end

  test "dosen melihat cabang Kepegawaian, bukan Akademik" do
    sign_in users(:budi)
    get edit_profile_path

    assert_response :success
    assert_select "h2", text: "Informasi Kepegawaian"
    assert_select "h2", text: "Akademik", count: 0
    assert_select "label", text: "NIP / NIDN"
    assert_select "select[name=?]", "user[profession_category]"
  end

  test "mahasiswa menyimpan biodata lengkap" do
    sign_in users(:siti)
    patch profile_path, params: { user: {
      full_name: "Siti Mahasiswa", identifier_number: "130110240001", phone: "081234567890",
      gender: "Perempuan", birth_place: "Bandung", birth_date: "2004-03-17",
      address: "Jl. Dipati Ukur 35", cohort_year: 2024, study_program_id: study_programs(:sarjana_kedokteran).id
    } }
    assert_redirected_to profile_path

    siti = users(:siti).reload
    assert_equal "130110240001", siti.identifier_number
    assert_equal "Perempuan", siti.gender
    assert_equal Date.new(2004, 3, 17), siti.birth_date
    assert_equal 2024, siti.cohort_year
    assert_empty siti.missing_profile_fields
    assert_equal 100, siti.profile_completeness

    get profile_path
    assert_match "Profil Anda sudah lengkap", response.body
    assert_match "130110240001", response.body
    assert_match "Bandung", response.body
  end

  test "dosen menyimpan data kepegawaian" do
    sign_in users(:budi)
    patch profile_path, params: { user: {
      identifier_number: "198501012010121001", phone: "0811223344", gender: "Laki-laki", birth_date: "1985-01-01",
      work_unit: "Departemen Ilmu Penyakit Dalam", position: "Dosen Preseptor",
      profession_category: "Dokter Spesialis", specialization: "Kardiologi"
    } }
    assert_redirected_to profile_path

    budi = users(:budi).reload
    assert_equal "Dokter Spesialis", budi.profession_category
    assert_equal "Kardiologi", budi.specialization
    assert_empty budi.missing_profile_fields

    get profile_path
    assert_match "Departemen Ilmu Penyakit Dalam", response.body
    assert_match "Kardiologi", response.body
  end

  test "profil belum lengkap menampilkan daftar isian yang kurang" do
    users(:siti).update_columns(identifier_number: nil, phone: nil, gender: nil, birth_date: nil, cohort_year: nil)
    sign_in users(:siti)
    get profile_path

    assert_response :success
    assert_match "Profil terisi", response.body
    assert_match "NPM / NIM", response.body
    assert_match "Angkatan", response.body
    assert_operator users(:siti).profile_completeness, :<, 100
  end

  test "nilai tidak masuk akal ditolak dan form ditampilkan ulang" do
    sign_in users(:siti)

    patch profile_path, params: { user: { birth_date: 1.year.from_now.to_date } }
    assert_response :unprocessable_entity
    assert_match "tidak boleh di masa depan", response.body

    patch profile_path, params: { user: { phone: "telepon rumah" } }
    assert_response :unprocessable_entity

    patch profile_path, params: { user: { gender: "Lainnya" } }
    assert_response :unprocessable_entity

    patch profile_path, params: { user: { cohort_year: 1800 } }
    assert_response :unprocessable_entity

    assert_nil users(:siti).reload.gender
  end

  test "peran dan email tidak bisa diubah lewat form profil" do
    sign_in users(:siti)
    patch profile_path, params: { user: { email: "baru@example.com", role_ids: [ roles(:admin).id ] } }

    siti = users(:siti).reload
    assert_equal "siti@example.com", siti.email
    assert_equal [ "mahasiswa" ], siti.roles.pluck(:code)
  end

  test "usia dihitung dari tanggal lahir" do
    users(:siti).update!(birth_date: 20.years.ago.to_date)
    assert_equal 20, users(:siti).age
    users(:budi).update!(birth_date: nil)
    assert_nil users(:budi).age
  end

  test "profil mahasiswa menampilkan blok tutorial & rotasi berjalan" do
    sign_in users(:siti)
    get profile_path

    assert_response :success
    assert_match tutorial_enrollments(:siti_kardio).block_name, response.body
    assert_match clinical_rotations(:ongoing_rotation_siti).station_name, response.body
  end
end
