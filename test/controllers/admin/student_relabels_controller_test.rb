require "test_helper"

class Admin::StudentRelabelsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @admin.update!(active_role: roles(:admin))
    @kaprodi = users(:dedi) # kaprodi Sarjana Kedokteran
    @pssk = study_programs(:sarjana_kedokteran)
    @pspd = study_programs(:profesi_dokter)
  end

  def create_student(email, program:)
    user = User.create!(full_name: email.split("@").first.capitalize, email: email, password: "password123",
                        confirmed_at: Time.current, study_program: program)
    user.roles << roles(:mahasiswa)
    user
  end

  def csv_upload(content)
    Rack::Test::UploadedFile.new(StringIO.new(content), "text/csv", original_filename: "relabel.csv")
  end

  test "selain admin dan kaprodi ditolak" do
    sign_in users(:wati)
    get new_admin_student_relabel_path
    assert_redirected_to dashboard_path

    post admin_student_relabel_path, params: { target_study_program_id: @pspd.id, csv_raw: "email\nsiti@example.com\n", apply: "1" }
    assert_redirected_to dashboard_path
    assert_equal @pssk, users(:siti).reload.study_program
  end

  test "kaprodi tanpa prodi diarahkan ke admin" do
    @kaprodi.update!(study_program: nil)
    sign_in @kaprodi
    get new_admin_student_relabel_path

    assert_redirected_to dashboard_path
    assert_match "belum terhubung ke Program Studi", flash[:alert]
  end

  test "admin membuka form dan menu tampil di Konfigurasi" do
    sign_in @admin
    get new_admin_student_relabel_path

    assert_response :success
    assert_select "aside#sidebar a[href=?]", new_admin_student_relabel_path, text: "Relabel Prodi Mahasiswa", count: 1
    assert_select "input[type=radio][name=mode]", count: 0
  end

  test "pratinjau admin menampilkan kecocokan tanpa mengubah data" do
    sign_in @admin
    post admin_student_relabel_path, params: {
      target_study_program_id: @pspd.id,
      csv_file: csv_upload("email,npm\nsiti@example.com,1306001\nhantu@example.com,\n")
    }

    assert_response :unprocessable_entity
    assert_match "1 dari 2 baris siap diproses", response.body
    assert_match "tidak ditemukan", response.body
    assert_select "input[type=hidden][name=csv_raw][value*=?]", "siti@example.com"
    assert_equal @pssk, users(:siti).reload.study_program
  end

  test "admin menerapkan relabel dari hidden csv_raw" do
    sign_in @admin
    post admin_student_relabel_path, params: {
      apply: "1", mode: "pindah", target_study_program_id: @pspd.id, default_cohort_year: "2026",
      csv_raw: "email,npm\nsiti@example.com,1306001\nbudi@example.com,\n"
    }

    assert_redirected_to new_admin_student_relabel_path
    assert_match "1 akun kini berlabel Profesi Dokter, 1 dilewati", flash[:notice]
    siti = users(:siti).reload
    assert_equal @pspd, siti.study_program
    assert_equal "1306001", siti.identifier_number
    assert_equal 2026, siti.cohort_year
    assert_nil users(:budi).reload.study_program
  end

  test "tanpa prodi tujuan atau tanpa kolom email ditolak dengan pesan" do
    sign_in @admin
    post admin_student_relabel_path, params: { csv_raw: "email\nsiti@example.com\n" }
    assert_response :unprocessable_entity
    assert_match "Pilih program studi tujuan", response.body

    post admin_student_relabel_path, params: { target_study_program_id: @pspd.id, csv_file: csv_upload("nama\nSiti\n") }
    assert_response :unprocessable_entity
    assert_match "Kolom &#39;email&#39; tidak ditemukan", response.body
  end

  test "klaim kaprodi selalu ke prodinya sendiri walau form mengirim prodi lain" do
    orang_pspd = create_student("pspd@example.com", program: @pspd)
    sign_in @kaprodi
    post admin_student_relabel_path, params: {
      apply: "1", mode: "klaim", target_study_program_id: @pspd.id,
      csv_raw: "email\npspd@example.com\n"
    }

    assert_redirected_to new_admin_student_relabel_path
    assert_equal @pssk, orang_pspd.reload.study_program
  end

  test "pindah oleh kaprodi hanya untuk mahasiswa prodinya sendiri" do
    tanpa_prodi = create_student("tanpa@example.com", program: nil)
    sign_in @kaprodi
    post admin_student_relabel_path, params: {
      apply: "1", mode: "pindah", target_study_program_id: @pspd.id,
      csv_raw: "email\nsiti@example.com\ntanpa@example.com\n"
    }

    assert_match "1 akun kini berlabel Profesi Dokter, 1 dilewati", flash[:notice]
    assert_equal @pspd, users(:siti).reload.study_program
    assert_nil tanpa_prodi.reload.study_program
  end

  test "kaprodi melihat pilihan aksi dan menu di Coaching Center" do
    sign_in @kaprodi
    get new_admin_student_relabel_path

    assert_response :success
    assert_select "input[type=radio][name=mode]", count: 2
    assert_select "aside#sidebar a[href=?]", new_admin_student_relabel_path, count: 1
    assert_select "aside#sidebar a[href=?]", admin_users_path, count: 0
  end

  test "template CSV bisa diunduh" do
    sign_in @admin
    get template_admin_student_relabel_path(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert response.body.start_with?("email,npm,angkatan")
  end
end
