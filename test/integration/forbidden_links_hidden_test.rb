require "test_helper"

# Tautan hanya tampil bila tujuannya boleh dibuka pengguna — dulu beberapa
# halaman menautkan ke halaman yang kemudian menolak dengan "Anda tidak
# memiliki akses" / "Halaman ini khusus admin" (ditemukan lewat crawl
# produksi per peran).
class ForbiddenLinksHiddenTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "tombol Peta Baru kerangka kompetensi hanya untuk admin" do
    sign_in users(:siti)
    get competency_frameworks_path
    assert_response :success
    assert_select "a[href=?]", new_competency_framework_path, 0

    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    get competency_frameworks_path
    assert_select "a[href=?]", new_competency_framework_path
  end

  test "Capaian Belajar mahasiswa: pembimbing lain melihat nama DOPS & Mini-CEX tanpa tautan rincian" do
    dops = dops_evaluations(:dops_siti_infus)
    mini_cex = mini_cex_evaluations(:minicex_siti_demam)

    sign_in users(:wati) # preseptor, bukan penilai kedua evaluasi ini
    get academic_assessments_path(student_id: users(:siti).id)
    assert_response :success
    assert_match dops.procedure_name, response.body
    assert_select "a[href=?]", dops_evaluation_path(dops), 0
    assert_select "a[href=?]", mini_cex_evaluation_path(mini_cex), 0

    sign_in users(:budi) # penilai keduanya
    get academic_assessments_path(student_id: users(:siti).id)
    assert_select "a[href=?]", dops_evaluation_path(dops)
    assert_select "a[href=?]", mini_cex_evaluation_path(mini_cex)
  end

  test "kaprodi di Learning Unit melihat nama event tanpa tautan ke halaman admin" do
    unit = LearningUnit.create!(name: "Blok Uji Tautan", study_program: study_programs(:sarjana_kedokteran),
                                academic_period: academic_periods(:current_period))
    unit.assessment_mappings.create!(assessment_event: assessment_events(:cbt_blok), weight: 100)

    sign_in users(:dedi)
    get admin_learning_unit_path(unit)
    assert_response :success
    assert_match assessment_events(:cbt_blok).name, response.body
    assert_select "a[href=?]", admin_assessment_event_path(assessment_events(:cbt_blok)), 0
  end
end
