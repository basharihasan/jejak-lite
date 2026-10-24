require "test_helper"

# Fase 24 — Pilar A: identitas pasien terenkripsi, Privacy Mode, Break Glass
# beraudit, persetujuan pasien via QR, master diagnosis, target kasus.
class PatientPrivacyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @case = clinical_cases(:submitted_case_siti)
    @case.update!(patient_name: "Ahmad Fauzi", patient_medical_record_number: "00123456",
                  patient_birth_date: "1990-05-10", patient_phone: "08123", patient_address: "Jl. Mawar 1")
  end

  test "identitas pasien tersimpan terenkripsi di basis data" do
    raw = ActiveRecord::Base.connection.select_value("SELECT patient_name FROM clinical_cases WHERE id = #{@case.id}")
    assert_not_equal "Ahmad Fauzi", raw
    assert_equal "Ahmad Fauzi", @case.reload.patient_name
  end

  test "Privacy Mode bawaan menyala dan menyamarkan identitas bahkan bagi pemilik" do
    assert AppSetting.privacy_mode?
    sign_in users(:siti)
    get clinical_case_path(@case)

    assert_response :success
    assert_no_match "Ahmad Fauzi", response.body
    assert_no_match "00123456", response.body
    assert_match "AF***", response.body
    assert_match "RM-****56", response.body
    assert_match "Break Glass", response.body
  end

  test "usia & pekerjaan pasien bukan data sensitif: tampil saat Privacy Mode dan di luar kotak sensitif form" do
    @case.update!(patient_age: 47, patient_occupation: "Nelayan")
    sign_in users(:siti)

    get clinical_case_path(@case)
    assert_match "(47 th)", response.body
    assert_match "Nelayan", response.body
    assert_no_match "Ahmad Fauzi", response.body

    get new_clinical_case_path
    assert_response :success
    doc = Nokogiri::HTML5(response.body)
    kotak_sensitif = doc.css("div.ring-amber-200").find { |div| div.text.include?("Data sensitif") }
    assert kotak_sensitif, "kotak Data sensitif harus ada"
    assert kotak_sensitif.at_css("#clinical_case_patient_name")
    assert_nil kotak_sensitif.at_css("#clinical_case_patient_age")
    assert_nil kotak_sensitif.at_css("#clinical_case_patient_occupation")
    assert doc.at_css("#clinical_case_patient_age")
    assert doc.at_css("#clinical_case_patient_occupation")
  end

  test "Break Glass beralasan membuka identitas 30 menit dan tercatat" do
    dosen = instructor("dosen")
    sign_in dosen

    assert_difference "BreakGlassAccess.count", 1 do
      post break_glass_clinical_case_path(@case), params: { reason: "Verifikasi kesesuaian identitas rekam medis" }
    end
    assert_redirected_to clinical_case_path(@case)

    get clinical_case_path(@case)
    assert_match "Ahmad Fauzi", response.body
    assert_match "00123456", response.body
    assert_match "Terbuka lewat Break Glass", response.body

    access = BreakGlassAccess.last
    assert_equal dosen, access.user
    assert_in_delta 30.minutes.from_now, access.expires_at, 5

    # Akses kedaluwarsa → tersamar lagi
    access.update!(expires_at: 1.minute.ago)
    get clinical_case_path(@case)
    assert_no_match "Ahmad Fauzi", response.body
  end

  test "preseptor rotasi yang mencakup tanggal kasus melihat identitas tanpa Break Glass" do
    sign_in users(:wati)
    get clinical_case_path(@case)

    assert_response :success
    assert_match "Ahmad Fauzi", response.body
    assert_match "00123456", response.body
    assert_match "pembimbing kasus ini", response.body
    assert_no_match "Disamarkan oleh Privacy Mode", response.body
  end

  test "preseptor yang rotasinya tidak mencakup tanggal kasus tetap tersamar" do
    @case.update!(case_date: 30.days.ago.to_date)
    sign_in users(:wati)
    get clinical_case_path(@case)

    assert_response :success
    assert_no_match "Ahmad Fauzi", response.body
    assert_match "AF***", response.body
    assert_match "Break Glass", response.body
  end

  test "dosen verifier kasus melihat identitas; dosen lain tetap tersamar" do
    verifier = instructor("dosen")
    @case.update!(verified_by: verifier)

    sign_in verifier
    get clinical_case_path(@case)
    assert_match "Ahmad Fauzi", response.body
    assert_match "pembimbing kasus ini", response.body

    sign_in instructor("dosen", email: "dosen.lain@example.com")
    get clinical_case_path(@case)
    assert_response :success
    assert_no_match "Ahmad Fauzi", response.body
    assert_match "AF***", response.body
  end

  test "Break Glass tanpa alasan memadai ditolak" do
    sign_in users(:budi)
    assert_no_difference "BreakGlassAccess.count" do
      post break_glass_clinical_case_path(@case), params: { reason: "cek" }
    end
    follow_redirect!
    assert_match "Break Glass ditolak", response.body
  end

  test "pengguna yang tidak boleh membuka kasus tidak bisa Break Glass" do
    other_student = User.create!(full_name: "Mahasiswa Lain", email: "lain@example.com", password: "password123",
                                 confirmed_at: Time.current)
    other_student.roles << roles(:mahasiswa)
    sign_in other_student

    assert_no_difference "BreakGlassAccess.count" do
      post break_glass_clinical_case_path(@case), params: { reason: "Ingin tahu saja padahal bukan kasus saya" }
    end
    assert_response :redirect
  end

  test "admin mematikan Privacy Mode lalu identitas tampil; audit terlihat di Data Governance" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    BreakGlassAccess.grant!(user: admin, clinical_case: @case, reason: "Audit internal kelengkapan data")
    get admin_data_governance_path
    assert_response :success
    assert_match "Audit internal kelengkapan data", response.body
    assert_match "Menyala", response.body

    patch admin_data_governance_path, params: { privacy_mode: "false" }
    assert_redirected_to admin_data_governance_path
    assert_not AppSetting.privacy_mode?

    sign_in users(:siti)
    get clinical_case_path(@case)
    assert_match "Ahmad Fauzi", response.body
  end

  test "ENV PRIVACY_MODE mengunci sakelar" do
    ENV["PRIVACY_MODE"] = "true"
    AppSetting.set_privacy_mode!(false, by: nil)
    assert AppSetting.privacy_mode?
    assert AppSetting.privacy_mode_locked_by_env?
  ensure
    ENV.delete("PRIVACY_MODE")
  end

  test "mahasiswa menerbitkan QR persetujuan; pasien menjawab tanpa login; hasil tampil di kasus" do
    sign_in users(:siti)
    assert_difference "PatientConsent.count", 1 do
      post issue_consent_clinical_case_path(@case)
    end
    consent = @case.reload.patient_consent
    assert consent.pending?

    get clinical_case_path(@case)
    assert_match public_patient_consent_path(consent.token), response.body
    assert_match "<svg", response.body # QR

    sign_out users(:siti)
    get public_patient_consent_path(consent.token)
    assert_response :success
    assert_select "aside#sidebar", count: 0
    assert_no_match @case.chief_complaint, response.body # isi kasus tidak pernah ditampilkan ke pasien

    patch public_patient_consent_path(consent.token), params: {
      items: { education: "1", photo: "0", publication: "1" }, signer_name: "Ahmad F.", signer_relation: "pasien"
    }
    assert_redirected_to public_patient_consent_path(consent.token)
    consent.reload
    assert consent.signed?
    assert consent.granted?("education")
    assert_not consent.granted?("photo")
    assert consent.granted?("publication")

    sign_in users(:siti)
    get clinical_case_path(@case)
    assert_match "Dijawab oleh Ahmad F.", response.body
  end

  test "pasien tanpa nama ditolak dan lembar yang dicabut tidak bisa diisi" do
    consent = @case.create_patient_consent!
    patch public_patient_consent_path(consent.token), params: { items: { education: "1" }, signer_name: "" }
    assert_response :unprocessable_entity

    consent.revoke!
    patch public_patient_consent_path(consent.token), params: { items: { education: "1" }, signer_name: "X" }
    assert_redirected_to public_patient_consent_path(consent.token)
    assert_not consent.reload.signed?
  end

  test "token tak dikenal → 404" do
    get public_patient_consent_path("bukan-token")
    assert_response :not_found
  end

  test "diagnosis yang cocok dengan master mengisi ICD-10 & level SKDI" do
    DiagnosisDefinition.create!(name: "Demam tifoid", icd10_code: "A01.0", skdi_level: "4A")
    @case.update!(diagnosis: "demam tifoid")
    assert_equal "A01.0", @case.icd10_code
    assert_equal "4A", @case.skdi_level

    @case.update!(diagnosis: "A01.0 — Demam tifoid")
    assert_equal "A01.0", @case.icd10_code

    @case.update!(diagnosis: "Penyakit langka tanpa master")
    assert_nil @case.icd10_code
  end

  test "usia dihitung dari tanggal lahir bila kolom usia kosong" do
    @case.update!(case_date: Date.new(2026, 5, 9))
    assert_equal 35, @case.display_age
    @case.update!(patient_age: 40)
    assert_equal 40, @case.display_age
  end

  test "kartu target kasus FKTP/FKRTL menghitung kasus terverifikasi per fasilitas" do
    LogbookCaseTarget.create!(study_program: study_programs(:sarjana_kedokteran), facility_type: "fktp", target_count: 5)
    LogbookCaseTarget.create!(study_program: study_programs(:sarjana_kedokteran), facility_type: "fkrtl", target_count: 10)
    @case.update!(clinical_setting: "pelayanan_primer", status: "verified")

    sign_in users(:siti)
    get clinical_cases_path
    assert_response :success
    assert_match "Pemenuhan Target Kasus", response.body
    assert_match %r{<span class="font-bold text-gray-800">1</span> / 5}, response.body
  end

  test "admin mengelola master diagnosis dan mengimpor CSV" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    post admin_diagnosis_definitions_path, params: { diagnosis_definition: { name: "Hipertensi esensial", icd10_code: "I10", skdi_level: "4A", active: "1" } }
    assert_redirected_to admin_diagnosis_definitions_path

    csv = Rack::Test::UploadedFile.new(StringIO.new("nama,kode_icd10,level_skdi,sistem\nHipertensi esensial,I10,4A,Kardio\nAsma bronkial,J45.9,4A,Respirasi\n,,,\n"), "text/csv", original_filename: "dx.csv")
    assert_difference "DiagnosisDefinition.count", 1 do
      post import_admin_diagnosis_definitions_path, params: { file: csv }
    end
    follow_redirect!
    assert_match "1 baru, 1 diperbarui", response.body
    assert_equal "Kardio", DiagnosisDefinition.find_by(name: "Hipertensi esensial").system_group

    get admin_skill_definitions_path
    assert_response :success
  end

  test "bukan admin tidak bisa membuka Data Governance dan master data" do
    sign_in users(:siti)
    get admin_data_governance_path
    assert_redirected_to dashboard_path
    get admin_diagnosis_definitions_path
    assert_redirected_to dashboard_path
  end
test "halaman tambah/sunting master data dan target kasus terbuka untuk admin" do
  admin = users(:budi)
  admin.roles << roles(:admin)
  sign_in admin

  get new_admin_diagnosis_definition_path
  assert_response :success
  get new_admin_skill_definition_path
  assert_response :success
  dx = DiagnosisDefinition.create!(name: "Skabies", icd10_code: "B86", skdi_level: "4A")
  get edit_admin_diagnosis_definition_path(dx)
  assert_response :success
  get new_admin_logbook_case_target_path
  assert_response :success
  get admin_logbook_case_targets_path
  assert_response :success
end

  private

  # Pengajar yang bukan pembimbing kasus fixture (tidak memegang rotasi siti).
  def instructor(role_code, email: "#{role_code}.baru@example.com")
    user = User.create!(full_name: "Pengajar Baru", email: email, password: "password123", confirmed_at: Time.current)
    user.roles << roles(role_code)
    user
  end
end
