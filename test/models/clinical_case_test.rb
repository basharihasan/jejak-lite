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

  test "request_revision! menyimpan komentar dan mengirim notifikasi" do
    kasus = clinical_cases(:submitted_case_siti)

    assert_difference "Notification.count", 1 do
      kasus.request_revision!(by: users(:budi), comment: "Lengkapi tatalaksana.")
    end

    assert_equal "needs_revision", kasus.reload.status
    assert_equal "Lengkapi tatalaksana.", kasus.verification_comment
  end
end
