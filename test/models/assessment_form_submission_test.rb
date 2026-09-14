require "test_helper"

class AssessmentFormSubmissionTest < ActiveSupport::TestCase
  # Submission yang sah minimal menjawab seluruh pertanyaan wajib templatenya.
  def build_submission(**attrs)
    template = assessment_form_templates(:tutor_evaluation)
    submission = AssessmentFormSubmission.new(
      { assessment_form_template: template, respondent: users(:siti), submitted_at: Time.current }.merge(attrs)
    )
    submission.assessment_form_answers.build(assessment_form_field: assessment_form_fields(:kejelasan_materi), value: "4")
    submission
  end

  test "subject_user wajib kalau template requires_subject_user" do
    submission = build_submission

    assert_not submission.valid?
    assert_includes submission.errors[:subject_user], "wajib dipilih untuk formulir ini"
  end

  test "pertanyaan wajib yang tidak dijawab menolak submission" do
    submission = build_submission(subject_user: users(:budi))
    submission.assessment_form_answers.first.value = ""

    assert_not submission.valid?
    assert_match "Pertanyaan wajib belum dijawab", submission.errors.full_messages.to_sentence
  end

  test "nilai rubrik = rata-rata terbobot pertanyaan skor" do
    template = assessment_form_templates(:tutor_evaluation)
    berat = template.assessment_form_fields.create!(label: "Penalaran klinis", field_type: "score", max_score: 10, weight: 3, required: true)

    submission = build_submission(subject_user: users(:budi))
    submission.assessment_form_answers.build(assessment_form_field: berat, value: "8")
    submission.save!

    # rating 4/5 bobot 1 = 0,8 · skor 8/10 bobot 3 = 0,8 → 80%
    assert_equal 80.0, submission.score_percentage
    assert submission.scorable?
  end

  test "jawaban di luar skala ditolak" do
    submission = build_submission(subject_user: users(:budi))
    submission.assessment_form_answers.first.value = "9" # skala rating 1-5

    assert_not submission.valid?
    assert_match "harus bernilai 1–5", submission.errors.full_messages.to_sentence
  end

  test "respondent_visible_to? menyembunyikan identitas dari subjek kalau anonim" do
    submission = build_submission(subject_user: users(:budi))
    submission.save!

    assert_not submission.respondent_visible_to?(users(:budi)) # subjek yang dinilai
    assert submission.respondent_visible_to?(users(:siti)) # respondennya sendiri

    admin = users(:budi)
    admin.roles << roles(:admin)
    assert submission.respondent_visible_to?(admin) # admin selalu bisa lihat
  end
end
