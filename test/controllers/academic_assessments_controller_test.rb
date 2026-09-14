require "test_helper"

class AcademicAssessmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa melihat capaian pribadinya pada periode berjalan" do
    sign_in users(:siti)

    get academic_assessments_path
    assert_response :success
    assert_match dops_evaluations(:dops_siti_infus).procedure_name, response.body
    assert_match assessment_events(:cbt_blok).name, response.body
  end

  test "tidak menampilkan data mahasiswa lain" do
    sign_in users(:budi)

    get academic_assessments_path
    assert_response :success
    assert_no_match dops_evaluations(:dops_siti_infus).procedure_name, response.body
  end

  test "menampilkan peta kompetensi dan badge target milestone" do
    sign_in users(:siti)

    get academic_assessments_path
    assert_response :success
    assert_match "Peta Kompetensi DOPS", response.body
    assert_match competency_milestones(:klinis_target_current_period).competency_item.title, response.body
    assert_match "target 7/9", response.body
  end
end
