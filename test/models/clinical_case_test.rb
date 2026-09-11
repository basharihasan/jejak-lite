require "test_helper"

class ClinicalCaseTest < ActiveSupport::TestCase
  test "wajib punya chief_complaint dan case_date" do
    kasus = ClinicalCase.new(user: users(:siti))
    assert_not kasus.valid?
    assert_includes kasus.errors[:chief_complaint], "tidak boleh kosong"
    assert_includes kasus.errors[:case_date], "tidak boleh kosong"
  end

  test "editable_by_owner? true untuk draft dan needs_revision saja" do
    assert clinical_cases(:draft_case_siti).editable_by_owner?
    assert_not clinical_cases(:submitted_case_siti).editable_by_owner?
  end

  test "verify! menandai terverifikasi dan mengirim notifikasi" do
    kasus = clinical_cases(:submitted_case_siti)

    assert_difference "Notification.count", 1 do
      kasus.verify!(by: users(:budi))
    end

    assert_equal "verified", kasus.reload.status
    assert_equal users(:budi), kasus.verified_by
    assert_equal kasus, Notification.last.notifiable
  end

  test "verify! mencatat entrustment level dan flag remediasi" do
    kasus = clinical_cases(:submitted_case_siti)
    kasus.verify!(by: users(:budi), entrustment_level: "supervisi_langsung", recommend_remediation: true, comment: "Pertahankan.")

    kasus.reload
    assert_equal "supervisi_langsung", kasus.entrustment_level
    assert kasus.recommend_remediation?
    assert_equal "verified", kasus.case_verification_comments.last.action
    assert_equal "Pertahankan.", kasus.case_verification_comments.last.body
  end

  test "request_revision! menyimpan riwayat komentar dan mengirim notifikasi" do
    kasus = clinical_cases(:submitted_case_siti)

    assert_difference "Notification.count", 1 do
      kasus.request_revision!(by: users(:budi), comment: "Lengkapi tatalaksana.")
    end

    assert_equal "needs_revision", kasus.reload.status
    comment = kasus.case_verification_comments.last
    assert_equal "revision_requested", comment.action
    assert_equal "Lengkapi tatalaksana.", comment.body
    assert_equal users(:budi), comment.user
  end

  test "submit! mencatat riwayat pengiriman" do
    kasus = clinical_cases(:draft_case_siti)
    kasus.submit!

    comment = kasus.case_verification_comments.last
    assert_equal "submitted", comment.action
    assert_equal kasus.user, comment.user
  end

  test "bmi menghitung dari berat dan tinggi badan" do
    kasus = clinical_cases(:submitted_case_siti)
    kasus.vital_signs = { "weight_kg" => 70, "height_cm" => 175 }

    assert_equal 22.9, kasus.bmi
  end

  test "bmi nil kalau berat atau tinggi belum diisi" do
    kasus = clinical_cases(:draft_case_siti)
    assert_nil kasus.bmi
  end
end
