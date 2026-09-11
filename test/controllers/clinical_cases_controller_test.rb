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
    assert_equal "Tambahkan diagnosis banding.", kasus.verification_comment
  end
end
