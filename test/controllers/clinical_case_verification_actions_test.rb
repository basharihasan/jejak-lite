require "test_helper"

# Paket Dasar Pilar A: verifikasi kasus lengkap — tolak, batalkan verifikasi,
# dan komentar tanpa mengubah status.
class ClinicalCaseVerificationActionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @kasus = clinical_cases(:submitted_case_siti)
  end

  test "dosen menolak kasus dengan alasan; kasus final dan mahasiswa diberi tahu" do
    sign_in users(:budi)

    patch reject_clinical_case_path(@kasus), params: { comment: "Duplikat dari kasus 3 hari lalu." }

    assert_redirected_to clinical_case_path(@kasus)
    assert_equal "rejected", @kasus.reload.status
    assert_equal "rejected", @kasus.case_verification_comments.last.action
    assert Notification.where(recipient: users(:siti), title: "Kasus klinis ditolak").exists?

    sign_in users(:siti)
    get clinical_case_path(@kasus)
    assert_match "Ditolak", response.body
    assert_no_match "Kirim untuk Verifikasi", response.body
    patch submit_clinical_case_path(@kasus)
    assert_equal "rejected", @kasus.reload.status
  end

  test "penolakan tanpa alasan ditolak" do
    sign_in users(:budi)
    patch reject_clinical_case_path(@kasus), params: { comment: "" }
    assert_equal "submitted", @kasus.reload.status
  end

  test "mahasiswa tidak bisa menolak kasusnya sendiri" do
    sign_in users(:siti)
    patch reject_clinical_case_path(@kasus), params: { comment: "Coba tolak sendiri" }
    assert_equal "submitted", @kasus.reload.status
  end

  test "verifier membatalkan verifikasi: kasus kembali ke antrean dan level EPA dari kasus itu dicabut, keputusan lama pulih" do
    epa = competency_frameworks(:skdi_ringkas).domains.first
    sign_in users(:budi)
    post entrustment_decisions_path, params: { student_id: users(:siti).id, competency_item_id: epa.id, level: 2, justification: "Masih perlu supervisi penuh saat ini." }
    earlier = EntrustmentDecision.current.find_by!(student: users(:siti), competency_item: epa)

    patch verify_clinical_case_path(@kasus), params: { entrustment_level: "mandiri", epa_item_ids: [ epa.id ] }
    from_case = EntrustmentDecision.current.find_by!(student: users(:siti), competency_item: epa)
    assert_equal 4, from_case.level

    get clinical_case_path(@kasus)
    assert_match "Batalkan Verifikasi", response.body

    patch cancel_verification_clinical_case_path(@kasus), params: { reason: "Salah memilih kasus saat verifikasi." }

    @kasus.reload
    assert_equal "submitted", @kasus.status
    assert_nil @kasus.verified_by
    assert_nil @kasus.entrustment_level
    assert from_case.reload.revoked?
    assert_nil earlier.reload.superseded_at
    assert_equal earlier, EntrustmentDecision.current.find_by!(student: users(:siti), competency_item: epa)
    assert_equal "verification_cancelled", @kasus.case_verification_comments.last.action

    get entrustment_decisions_path(student_id: users(:siti).id)
    assert_match "dicabut", response.body
  end

  test "pengajar lain tidak boleh membatalkan verifikasi orang lain" do
    sign_in users(:budi)
    patch verify_clinical_case_path(@kasus), params: { entrustment_level: "mandiri" }

    sign_in users(:wati)
    patch cancel_verification_clinical_case_path(@kasus), params: { reason: "Bukan saya yang memverifikasi" }
    assert_equal "verified", @kasus.reload.status
  end

  test "mahasiswa dan dosen berdiskusi lewat komentar tanpa mengubah status" do
    sign_in users(:siti)
    get clinical_case_path(@kasus)
    assert_match "Kirim Komentar", response.body

    post comment_clinical_case_path(@kasus), params: { body: "Dok, apakah perlu saya tambahkan hasil USG?" }
    assert_redirected_to clinical_case_path(@kasus)

    sign_in users(:budi)
    post comment_clinical_case_path(@kasus), params: { body: "Ya, lampirkan hasil USG-nya." }

    assert_equal "submitted", @kasus.reload.status
    assert_equal %w[commented commented], @kasus.case_verification_comments.where(action: "commented").pluck(:action)
    assert Notification.where(recipient: users(:siti), title: "Komentar baru pada kasus klinis").exists?
  end

  test "komentar kosong tidak tersimpan" do
    sign_in users(:siti)
    assert_no_difference "CaseVerificationComment.count" do
      post comment_clinical_case_path(@kasus), params: { body: " " }
    end
  end
end
