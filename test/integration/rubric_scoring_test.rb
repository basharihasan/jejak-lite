require "test_helper"

# Perbaikan Assessment Form Builder × Assessment Event:
# rubrik diisi DARI lembar penguji, tersimpan tertaut ke percobaan, dan
# nilainya dihitung dari jawaban — bukan diketik ulang.
class RubricScoringTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @template = AssessmentFormTemplate.create!(name: "Rubrik SOCA", is_active: true, requires_subject_user: false)
    @anamnesis = @template.assessment_form_fields.create!(label: "Anamnesis", field_type: "rating", required: true, weight: 1)
    @penalaran = @template.assessment_form_fields.create!(label: "Penalaran klinis", field_type: "score", max_score: 10, weight: 3, required: true)
    @catatan = @template.assessment_form_fields.create!(label: "Catatan penguji", field_type: "textarea", required: false)

    @event = assessment_events(:soca_kardio)
    @event.update!(assessment_form_template: @template, max_score: 100)
    @instance = AssessmentInstance.create!(assessment_event: @event, student: users(:siti), attempt_number: 1,
                                           max_score: 100, examiner: users(:budi), status: "submitted", submitted_at: 1.day.ago)
  end

  test "penguji mengisi rubrik; nilai dihitung otomatis & lembarnya tertaut ke percobaan" do
    sign_in users(:budi)

    get examiner_evaluation_path(@instance)
    assert_response :success
    assert_match "Rubrik SOCA", response.body
    assert_match "Nilai dihitung otomatis", response.body
    assert_select "input[name=?]", "answers[#{@anamnesis.id}]"
    assert_select "input[name=?]", "answers[#{@penalaran.id}]"

    assert_difference "AssessmentFormSubmission.count", 1 do
      patch examiner_evaluation_path(@instance), params: {
        answers: { @anamnesis.id.to_s => "4", @penalaran.id.to_s => "8", @catatan.id.to_s => "Sistematis." },
        assessment_instance: { feedback_keep: "Anamnesis runtut.", feedback_improve: "Perdalam tata laksana." }
      }
    end
    assert_redirected_to examiner_evaluations_path

    @instance.reload
    # rating 4/5 bobot 1 = 0,8 · skor 8/10 bobot 3 = 0,8 → 80% × maks 100
    assert_equal 80.0, @instance.score.to_f
    assert_equal "scored", @instance.status
    assert_equal "rubric", @instance.source
    assert_equal users(:budi), @instance.examiner

    submission = @instance.assessment_form_submission
    assert_not_nil submission, "lembar rubrik harus tertaut ke percobaan"
    assert_equal users(:siti), submission.subject_user
    assert_equal 80.0, submission.score_percentage
    assert_equal "Sistematis.", submission.answer_for(@catatan).value
    assert Notification.where(recipient: users(:siti)).where("title LIKE ?", "%Nilai%").exists?
  end

  test "bobot benar-benar berpengaruh pada nilai akhir" do
    sign_in users(:budi)
    patch examiner_evaluation_path(@instance), params: {
      answers: { @anamnesis.id.to_s => "5", @penalaran.id.to_s => "5" } # 100% bobot 1, 50% bobot 3
    }
    # (1,0×1 + 0,5×3) / 4 = 0,625
    assert_equal 62.5, @instance.reload.score.to_f
  end

  test "pertanyaan wajib kosong menolak penilaian dan tidak menyisakan lembar yatim" do
    sign_in users(:budi)

    assert_no_difference [ "AssessmentFormSubmission.count", "AssessmentFormAnswer.count" ] do
      patch examiner_evaluation_path(@instance), params: { answers: { @anamnesis.id.to_s => "4" } }
    end
    assert_response :unprocessable_entity
    assert_match "Pertanyaan wajib belum dijawab", response.body
    assert_equal "submitted", @instance.reload.status
    assert_nil @instance.score
  end

  test "jawaban di luar skala ditolak" do
    sign_in users(:budi)
    patch examiner_evaluation_path(@instance), params: {
      answers: { @anamnesis.id.to_s => "4", @penalaran.id.to_s => "15" }
    }
    assert_response :unprocessable_entity
    assert_match "harus bernilai 0–10", response.body
  end

  test "mengisi ulang rubrik mengganti lembar lama, bukan menumpuk" do
    sign_in users(:budi)
    patch examiner_evaluation_path(@instance), params: { answers: { @anamnesis.id.to_s => "4", @penalaran.id.to_s => "8" } }
    first_submission = @instance.reload.assessment_form_submission

    assert_no_difference "AssessmentFormSubmission.count" do
      patch examiner_evaluation_path(@instance), params: { answers: { @anamnesis.id.to_s => "5", @penalaran.id.to_s => "10" } }
    end
    @instance.reload
    assert_equal 100.0, @instance.score.to_f
    assert_not_equal first_submission.id, @instance.assessment_form_submission_id
    assert_nil AssessmentFormSubmission.find_by(id: first_submission.id)
  end

  test "event tanpa rubrik tetap dinilai manual" do
    @event.update!(assessment_form_template: nil)
    sign_in users(:budi)

    get examiner_evaluation_path(@instance)
    assert_select "input[name=?]", "assessment_instance[score]"

    patch examiner_evaluation_path(@instance), params: { assessment_instance: { score: 77 } }
    assert_equal 77.0, @instance.reload.score.to_f
    assert_equal "manual", @instance.source
  end

  test "rubrik naratif saja tidak menghitung nilai — penguji mengisinya sendiri" do
    @anamnesis.destroy
    @penalaran.destroy
    sign_in users(:budi)

    get examiner_evaluation_path(@instance)
    assert_match "Rubrik naratif", response.body

    patch examiner_evaluation_path(@instance), params: {
      answers: { @catatan.id.to_s => "Cukup baik." }, assessment_instance: { score: 70 }
    }
    assert_equal 70.0, @instance.reload.score.to_f
  end

  # ── Assessment Form Builder ──
  test "jenis jawaban terkunci setelah ada jawaban" do
    sign_in users(:budi)
    patch examiner_evaluation_path(@instance), params: { answers: { @anamnesis.id.to_s => "4", @penalaran.id.to_s => "8" } }

    @admin.roles << roles(:admin)
    patch assessment_form_template_assessment_form_field_path(@template, @anamnesis), params: {
      assessment_form_field: { label: @anamnesis.label, field_type: "textarea" }
    }
    assert_response :unprocessable_entity
    assert_equal "rating", @anamnesis.reload.field_type
  end

  test "urutan pertanyaan dapat diubah" do
    @admin.roles << roles(:admin)
    sign_in @admin

    patch move_up_assessment_form_template_assessment_form_field_path(@template, @penalaran)
    assert_equal [ @penalaran.id, @anamnesis.id, @catatan.id ], @template.assessment_form_fields.ordered.pluck(:id)

    patch move_down_assessment_form_template_assessment_form_field_path(@template, @penalaran)
    assert_equal [ @anamnesis.id, @penalaran.id, @catatan.id ], @template.assessment_form_fields.ordered.pluck(:id)
  end

  test "template yang sudah dipakai tidak bisa dihapus" do
    @admin.roles << roles(:admin)
    sign_in @admin

    # Dipakai sebagai rubrik event
    assert_no_difference "AssessmentFormTemplate.count" do
      delete assessment_form_template_path(@template)
    end
    follow_redirect!
    assert_match "dipakai sebagai rubrik", response.body

    # Sudah punya jawaban: isi rubrik dulu, baru lepaskan dari event —
    # penghalangnya kini jawaban yang tersimpan, bukan tautan event.
    patch examiner_evaluation_path(@instance), params: { answers: { @anamnesis.id.to_s => "4", @penalaran.id.to_s => "8" } }
    @event.update!(assessment_form_template: nil)
    assert @template.reload.assessment_form_submissions.exists?

    assert_no_difference "AssessmentFormTemplate.count" do
      delete assessment_form_template_path(@template)
    end
    follow_redirect!
    assert_match "sudah punya jawaban", response.body
  end

  # ── Assessment Event ──
  test "impor CSV ditolak untuk event non-ujian meski alamatnya dibuka langsung" do
    @admin.roles << roles(:admin)
    sign_in @admin

    get import_admin_assessment_event_path(@event) # SOCA = rubrik
    assert_redirected_to admin_assessment_event_path(@event)
    follow_redirect!
    assert_match "hanya untuk ujian tulis/praktik", response.body

    assert_no_difference "AssessmentInstance.count" do
      post import_create_admin_assessment_event_path(@event), params: { csv_text: "email,score\nsiti@example.com,90\n", mapping: { email: "email", score: "score" } }
    end
  end

  test "mengubah nilai maksimum event ikut memperbarui percobaan yang belum dinilai saja" do
    @admin.roles << roles(:admin)
    sign_in @admin
    scored = AssessmentInstance.create!(assessment_event: @event, student: users(:wati), attempt_number: 1,
                                        max_score: 100, score: 80, status: "scored", scored_at: Time.current)

    patch admin_assessment_event_path(@event), params: { assessment_event: { max_score: 50 } }

    assert_equal 50, @instance.reload.max_score.to_i   # belum dinilai → ikut
    assert_equal 100, scored.reload.max_score.to_i     # sudah dinilai → dibiarkan
  end

  test "event yang sudah punya nilai tidak bisa dihapus" do
    @admin.roles << roles(:admin)
    sign_in @admin
    @instance.update!(status: "scored", score: 70, scored_at: Time.current)

    assert_no_difference "AssessmentEvent.count" do
      delete admin_assessment_event_path(@event)
    end
    follow_redirect!
    assert_match "tidak dapat dihapus", response.body
  end
end
