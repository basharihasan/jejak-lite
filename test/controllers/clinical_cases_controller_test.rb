require "test_helper"

class ClinicalCasesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get clinical_cases_path
    assert_redirected_to new_user_session_path
  end

  test "mahasiswa hanya melihat kasusnya sendiri di index" do
    sign_in users(:siti)
    get clinical_cases_path

    assert_response :success
    assert_match clinical_cases(:draft_case_siti).chief_complaint, response.body
  end

  test "mahasiswa tidak bisa melihat detail kasus milik orang lain" do
    other = User.create!(full_name: "Mahasiswa Lain", email: "lain@example.com", password: "password123", confirmed_at: Time.current)
    other.roles << roles(:mahasiswa)

    sign_in other
    get clinical_case_path(clinical_cases(:draft_case_siti))

    assert_response :redirect
  end

  test "dosen bisa melihat antrean perlu diverifikasi" do
    sign_in users(:budi)
    get clinical_cases_path(scope: "to_verify")

    assert_response :success
    assert_match clinical_cases(:submitted_case_siti).chief_complaint, response.body
    assert_no_match clinical_cases(:draft_case_siti).chief_complaint, response.body
  end

  test "mahasiswa membuat kasus baru sebagai draf" do
    sign_in users(:siti)

    assert_difference "ClinicalCase.count", 1 do
      post clinical_cases_path, params: {
        clinical_case: { case_date: Date.current, chief_complaint: "Batuk pilek", patient_age_group: "Anak" }
      }
    end

    assert_equal "draft", ClinicalCase.order(:id).last.status
  end

  test "mahasiswa mengisi dokumentasi klinis lengkap termasuk tanda vital" do
    sign_in users(:siti)

    assert_difference "ClinicalCase.count", 1 do
      post clinical_cases_path, params: {
        clinical_case: {
          case_date: Date.current, chief_complaint: "Demam 3 hari",
          anamnesis: "Demam sejak 3 hari, disertai nyeri kepala.",
          general_condition: "Tampak sakit sedang, kompos mentis.",
          physical_examination: "Faring hiperemis, tonsil T1-T1.",
          family_history: "Tidak ada riwayat penyakit serupa di keluarga.",
          vital_signs: { temperature: "38.5", pulse: "92", weight_kg: "60", height_cm: "165" }
        }
      }
    end

    kasus = ClinicalCase.order(:id).last
    assert_equal "Demam sejak 3 hari, disertai nyeri kepala.", kasus.anamnesis
    assert_equal "38.5", kasus.vital_sign("temperature")
    assert_in_delta 22.0, kasus.bmi, 0.1
  end

  test "halaman form kasus klinis menampilkan wizard 4 langkah" do
    sign_in users(:siti)
    get new_clinical_case_path

    assert_response :success
    assert_select "[data-controller='wizard']"
    assert_select "[data-wizard-target='step']", count: 4
  end

  test "mahasiswa mengirim draf untuk verifikasi" do
    sign_in users(:siti)
    kasus = clinical_cases(:draft_case_siti)

    patch submit_clinical_case_path(kasus)

    assert_equal "submitted", kasus.reload.status
  end

  test "mahasiswa tidak bisa memverifikasi kasusnya sendiri" do
    sign_in users(:siti)
    kasus = clinical_cases(:submitted_case_siti)

    patch verify_clinical_case_path(kasus)

    assert_response :redirect
    assert_equal "submitted", kasus.reload.status
  end

  # Regresi: akun multi-peran (mahasiswa+dosen sekaligus) tidak boleh
  # meloloskan diri dari larangan verifikasi kasus miliknya sendiri hanya
  # karena kebetulan juga menyandang peran dosen/admin.
  test "akun multi-peran tidak bisa memverifikasi kasus miliknya sendiri" do
    siti = users(:siti)
    siti.roles << roles(:dosen)
    sign_in siti
    kasus = clinical_cases(:submitted_case_siti)

    patch verify_clinical_case_path(kasus)

    assert_response :redirect
    assert_equal "submitted", kasus.reload.status
  end

  test "dosen memverifikasi kasus yang diajukan" do
    sign_in users(:budi)
    kasus = clinical_cases(:submitted_case_siti)

    patch verify_clinical_case_path(kasus)

    assert_equal "verified", kasus.reload.status
    assert_equal users(:budi), kasus.verified_by
  end

  test "dosen meminta revisi dengan komentar" do
    sign_in users(:budi)
    kasus = clinical_cases(:submitted_case_siti)

    patch request_revision_clinical_case_path(kasus), params: { comment: "Tambahkan diagnosis banding." }

    assert_equal "needs_revision", kasus.reload.status
    assert_equal "Tambahkan diagnosis banding.", kasus.case_verification_comments.last.body
  end

  test "dosen memverifikasi dengan entrustment level dan flag remediasi" do
    sign_in users(:budi)
    kasus = clinical_cases(:submitted_case_siti)

    patch verify_clinical_case_path(kasus), params: { entrustment_level: "mandiri", recommend_remediation: "1" }

    kasus.reload
    assert_equal "verified", kasus.status
    assert_equal "mandiri", kasus.entrustment_level
    assert kasus.recommend_remediation?
  end
end
