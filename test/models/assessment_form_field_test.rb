require "test_helper"

class AssessmentFormFieldTest < ActiveSupport::TestCase
  test "position ditetapkan otomatis mengikuti urutan pembuatan" do
    field = assessment_form_templates(:tutor_evaluation).assessment_form_fields.create!(label: "Pertanyaan baru", field_type: "text")
    assert_equal 3, field.position
  end

  test "field_type harus salah satu dari FIELD_TYPES" do
    field = AssessmentFormField.new(assessment_form_template: assessment_form_templates(:tutor_evaluation), label: "X", field_type: "invalid")
    assert_not field.valid?
  end

  test "pesan validasi pilihan kosong memakai nama atribut berbahasa Indonesia" do
    field = AssessmentFormField.new(assessment_form_template: AssessmentFormTemplate.first, label: "Kelayakan", field_type: "select")
    assert_not field.valid?
    assert_includes field.errors.full_messages.join, "Daftar pilihan / jenjang harus diisi"
    assert_not_includes field.errors.full_messages.join, "Options text"
  end
end
