require "test_helper"

# Mahasiswa boleh menandai dosen/preseptor pembimbing saat menulis kasus
# (opsional). Bila ditandai, HANYA pembimbing itu yang memverifikasi kasus —
# pengajar lain tidak; tanpa tanda kasus tetap terbuka bagi pengajar mana pun.
class ClinicalCaseSupervisorTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @kasus = clinical_cases(:draft_case_siti)
  end

  test "form kasus baru menawarkan dosen dan preseptor sebagai pembimbing, tidak wajib" do
    sign_in users(:siti)
    get new_clinical_case_path

    assert_response :success
    assert_select "select[name='clinical_case[supervisor_id]']" do
      assert_select "option[value='']", text: "— Tidak ditandai —"
      assert_select "option[value='#{users(:budi).id}']", text: "Budi Dosen"
      assert_select "option[value='#{users(:wati).id}']", text: "Wati Preseptor"
      assert_select "option[value='#{users(:dedi).id}']", count: 0
      assert_select "option[value='#{users(:siti).id}']", count: 0
    end
  end

  test "mahasiswa menandai preseptor saat menulis kasus" do
    sign_in users(:siti)

    post clinical_cases_path, params: {
      clinical_case: { case_date: Date.current, chief_complaint: "Sesak napas", supervisor_id: users(:wati).id }
    }

    kasus = ClinicalCase.order(:id).last
    assert_redirected_to clinical_case_path(kasus)
    assert_equal users(:wati), kasus.supervisor
  end

  test "yang ditandai harus dosen atau preseptor" do
    sign_in users(:siti)

    assert_no_difference "ClinicalCase.count" do
      post clinical_cases_path, params: {
        clinical_case: { case_date: Date.current, chief_complaint: "Sesak napas", supervisor_id: users(:dedi).id }
      }
    end
    assert_response :unprocessable_entity
    assert_match "Dosen/preseptor pembimbing harus dosen atau preseptor", response.body
  end

  test "pembimbing yang ditandai diberi tahu saat kasus dikirim" do
    @kasus.update!(supervisor: users(:wati))
    sign_in users(:siti)

    patch submit_clinical_case_path(@kasus)

    assert_equal "submitted", @kasus.reload.status
    assert Notification.where(recipient: users(:wati), notifiable: @kasus, title: "Kasus klinis menunggu verifikasi Anda").exists?
  end

  test "dosen lain tidak bisa memverifikasi, meminta revisi, atau menolak kasus yang menandai pembimbing lain" do
    @kasus.update!(supervisor: users(:wati), status: "submitted")
    sign_in users(:budi)

    get clinical_case_path(@kasus)
    assert_response :success
    assert_match "Menunggu verifikasi dari", response.body
    assert_no_match "Setujui / Verifikasi", response.body

    patch verify_clinical_case_path(@kasus), params: { entrustment_level: "mandiri" }
    patch request_revision_clinical_case_path(@kasus), params: { comment: "Lengkapi anamnesis." }
    patch reject_clinical_case_path(@kasus), params: { comment: "Duplikat." }
    assert_equal "submitted", @kasus.reload.status
    assert_nil @kasus.verified_by

    get clinical_cases_path(scope: "to_verify")
    assert_no_match @kasus.chief_complaint, response.body
  end

  test "pembimbing yang ditandai melihat kasus di antreannya dan memverifikasinya" do
    @kasus.update!(supervisor: users(:wati), status: "submitted")
    sign_in users(:wati)

    get clinical_cases_path(scope: "to_verify")
    assert_match @kasus.chief_complaint, response.body

    get clinical_case_path(@kasus)
    assert_match "Setujui / Verifikasi", response.body

    patch verify_clinical_case_path(@kasus), params: { entrustment_level: "mandiri" }
    assert_equal "verified", @kasus.reload.status
    assert_equal users(:wati), @kasus.verified_by
  end

  test "kasus tanpa tanda pembimbing tetap bisa diverifikasi pengajar mana pun" do
    kasus = clinical_cases(:submitted_case_siti)
    assert_nil kasus.supervisor
    sign_in users(:wati)

    patch verify_clinical_case_path(kasus), params: { entrustment_level: "mandiri" }
    assert_equal "verified", kasus.reload.status
  end
end
