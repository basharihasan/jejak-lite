require "test_helper"

class AssessmentFormSubmissionTest < ActiveSupport::TestCase
  test "subject_user wajib kalau template requires_subject_user" do
    submission = AssessmentFormSubmission.new(
      assessment_form_template: assessment_form_templates(:tutor_evaluation),
      respondent: users(:siti), submitted_at: Time.current
    )

    assert_not submission.valid?
    assert_includes submission.errors[:subject_user], "wajib dipilih untuk formulir ini"
  end

  test "respondent_visible_to? menyembunyikan identitas dari subjek kalau anonim" do
    submission = AssessmentFormSubmission.create!(
      assessment_form_template: assessment_form_templates(:tutor_evaluation),
      respondent: users(:siti), subject_user: users(:budi), submitted_at: Time.current
    )

    assert_not submission.respondent_visible_to?(users(:budi)) # subjek yang dinilai
    assert submission.respondent_visible_to?(users(:siti)) # respondennya sendiri

    admin = users(:budi)
    admin.roles << roles(:admin)
    assert submission.respondent_visible_to?(admin) # admin selalu bisa lihat
  end
end
