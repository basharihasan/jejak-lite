require "test_helper"

class AcademicAssessmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa melihat capaian pribadinya pada periode berjalan" do
    sign_in users(:siti)

    get academic_assessments_path
    assert_response :success
    assert_match dops_evaluations(:dops_siti_infus).procedure_name, response.body
    assert_match exam_imports(:cbt_blok1).kind_label, response.body
  end

  test "tidak menampilkan data mahasiswa lain" do
    sign_in users(:budi)

    get academic_assessments_path
    assert_response :success
    assert_no_match dops_evaluations(:dops_siti_infus).procedure_name, response.body
  end
end
