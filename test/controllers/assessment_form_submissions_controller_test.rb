require "test_helper"

class AssessmentFormSubmissionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mengisi formulir menyimpan jawaban per pertanyaan" do
    sign_in users(:siti)
    template = assessment_form_templates(:tutor_evaluation)
    rating_field = assessment_form_fields(:kejelasan_materi)

    assert_difference "AssessmentFormSubmission.count", 1 do
      post assessment_form_template_assessment_form_submissions_path(template), params: {
        assessment_form_submission: { subject_user_id: users(:budi).id },
        answers: { rating_field.id.to_s => "4" }
      }
    end

    submission = AssessmentFormSubmission.order(:id).last
    # Satu baris jawaban per PERTANYAAN template (yang opsional boleh kosong),
    # bukan hanya per parameter yang terkirim.
    assert_equal template.assessment_form_fields.count, submission.assessment_form_answers.count
    assert_equal "4", submission.answer_for(rating_field).value
  end

  test "pertanyaan wajib yang tidak dipilih tidak lagi lolos diam-diam" do
    sign_in users(:siti)
    template = assessment_form_templates(:tutor_evaluation)

    # Meniru radio yang tidak dipilih: parameternya tidak terkirim sama sekali.
    assert_no_difference "AssessmentFormSubmission.count" do
      post assessment_form_template_assessment_form_submissions_path(template), params: {
        assessment_form_submission: { subject_user_id: users(:budi).id },
        answers: { assessment_form_fields(:saran).id.to_s => "Sudah baik" }
      }
    end
    assert_response :unprocessable_entity
    assert_match "Pertanyaan wajib belum dijawab", response.body
  end

  test "subjek yang dinilai tidak melihat identitas responden pada formulir anonim" do
    submission = AssessmentFormSubmission.new(
      assessment_form_template: assessment_form_templates(:tutor_evaluation),
      respondent: users(:siti), subject_user: users(:budi), submitted_at: Time.current
    )
    submission.assessment_form_answers.build(assessment_form_field: assessment_form_fields(:kejelasan_materi), value: "4")
    submission.save!

    sign_in users(:budi)
    get assessment_form_submission_path(submission)

    assert_response :success
    assert_match "Anonim", response.body
    assert_no_match users(:siti).full_name, response.body
  end
end
