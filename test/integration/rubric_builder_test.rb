require "test_helper"

# Assessment Form Builder sebagai rubrik: jenis Rubrik Berjenjang & Pilihan
# Ganda, serta pemetaan pertanyaan → ranah kompetensi yang mengisi Peta
# Kompetensi mahasiswa.
class RubricBuilderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @template = AssessmentFormTemplate.create!(name: "Rubrik Mini-CEX Blok", is_active: true)
    @framework = competency_frameworks(:skdi_ringkas)
    @keterampilan = @framework.domains.find { |d| d.title.include?("Keterampilan") } || @framework.domains.first
    @komunikasi = (@framework.domains - [ @keterampilan ]).first
  end

  test "form pertanyaan menawarkan jenis rubrik & pemetaan kompetensi" do
    sign_in @admin
    get new_assessment_form_template_assessment_form_field_path(@template)

    assert_response :success
    assert_select "select[name=?] option[value=rubric_level]", "assessment_form_field[field_type]"
    assert_select "select[name=?] option[value=select]", "assessment_form_field[field_type]"
    assert_select "textarea[name=?]", "assessment_form_field[options_text]"
    assert_select "select[name=?]", "assessment_form_field[competency_item_id]"
    assert_match @keterampilan.title, response.body
    assert_match "Rubrik Berjenjang", response.body
  end

  test "rubrik berjenjang menyimpan deskriptor, skor, dan pemetaan kompetensi" do
    sign_in @admin

    assert_difference "AssessmentFormField.count", 1 do
      post assessment_form_template_assessment_form_fields_path(@template), params: {
        assessment_form_field: {
          label: "Penalaran klinis", field_type: "rubric_level", required: "1", weight: "2",
          competency_item_id: @keterampilan.id,
          options_text: "Belum kompeten | Belum mampu tanpa arahan | 1\nCukup | Mampu dengan bimbingan | 2\nBaik | Mandiri dengan supervisi | 3\nSangat baik | Mandiri dan menjelaskan alasannya | 4"
        }
      }
    end

    field = @template.assessment_form_fields.find_by!(label: "Penalaran klinis")
    assert_equal 4, field.option_rows.size
    assert_equal "Mampu dengan bimbingan", field.option_for("Cukup")[:description]
    assert_equal 3, field.option_for("Baik")[:score]
    assert_equal 4, field.max_score, "skala mengikuti jenjang tertinggi"
    assert field.scorable?
    assert_equal @keterampilan, field.competency_item
    # Jenjang "Baik" = 3 dari 4 → 75%
    assert_in_delta 0.75, field.normalized("Baik"), 0.001
  end

  test "rubrik berjenjang tanpa jenjang yang ditulis memakai empat jenjang bawaan" do
    sign_in @admin
    post assessment_form_template_assessment_form_fields_path(@template), params: {
      assessment_form_field: { label: "Profesionalisme", field_type: "rubric_level", options_text: "" }
    }
    field = @template.assessment_form_fields.find_by!(label: "Profesionalisme")
    assert_equal 4, field.option_rows.size
    assert_equal "Belum kompeten", field.option_rows.first[:label]
  end

  test "skor jenjang boleh dikosongkan — diisi urutan barisnya" do
    sign_in @admin
    post assessment_form_template_assessment_form_fields_path(@template), params: {
      assessment_form_field: { label: "Komunikasi", field_type: "rubric_level", options_text: "Kurang\nCukup\nBaik" }
    }
    field = @template.assessment_form_fields.find_by!(label: "Komunikasi")
    assert_equal [ 1, 2, 3 ], field.option_rows.map { |r| r[:score] }
    assert_equal 3, field.max_score
  end

  test "pilihan ganda tidak ikut menghitung nilai" do
    sign_in @admin
    post assessment_form_template_assessment_form_fields_path(@template), params: {
      assessment_form_field: { label: "Jenis kasus", field_type: "select", options_text: "Akut\nKronik", competency_item_id: @komunikasi.id }
    }
    field = @template.assessment_form_fields.find_by!(label: "Jenis kasus")
    assert_not field.scorable?
    assert_equal %w[Akut Kronik], field.option_values
    assert_nil field.normalized("Akut")
  end

  test "jenis berdaftar tanpa pilihan ditolak" do
    sign_in @admin
    assert_no_difference "AssessmentFormField.count" do
      post assessment_form_template_assessment_form_fields_path(@template), params: {
        assessment_form_field: { label: "Kosong", field_type: "select", options_text: "" }
      }
    end
    assert_response :unprocessable_entity
    assert_match "satu pilihan/jenjang per baris", response.body
  end

  test "jawaban di luar daftar jenjang ditolak" do
    field = @template.assessment_form_fields.create!(label: "Penalaran", field_type: "rubric_level",
                                                     options_text: "Kurang | | 1\nBaik | | 2")
    submission = @template.assessment_form_submissions.build(respondent: @admin, submitted_at: Time.current)
    submission.assessment_form_answers.build(assessment_form_field: field, value: "Luar Biasa")

    assert_not submission.valid?
    assert_match "tidak ada dalam daftar", submission.errors.full_messages.to_sentence
  end

  test "penguji menilai dengan rubrik berjenjang; nilai & peta kompetensi terisi" do
    penalaran = @template.assessment_form_fields.create!(label: "Penalaran klinis", field_type: "rubric_level", weight: 3,
                                                         competency_item: @keterampilan,
                                                         options_text: "Kurang | | 1\nCukup | | 2\nBaik | | 3\nSangat baik | | 4")
    komunikasi = @template.assessment_form_fields.create!(label: "Komunikasi", field_type: "rating", weight: 1,
                                                          competency_item: @komunikasi)
    event = assessment_events(:soca_kardio)
    event.update!(assessment_form_template: @template, max_score: 100)
    instance = AssessmentInstance.create!(assessment_event: event, student: users(:siti), attempt_number: 1,
                                          max_score: 100, examiner: users(:budi), status: "submitted", submitted_at: 1.day.ago)

    sign_in users(:budi)
    get examiner_evaluation_path(instance)
    assert_response :success
    assert_select "input[type=radio][name=?][value=?]", "answers[#{penalaran.id}]", "Sangat baik"

    patch examiner_evaluation_path(instance), params: {
      answers: { penalaran.id.to_s => "Baik", komunikasi.id.to_s => "4" }
    }
    instance.reload
    # Penalaran 3/4 = 75% bobot 3 · Komunikasi 4/5 = 80% bobot 1 → 76,25%,
    # dibulatkan satu desimal pada persentase rubrik → 76,3.
    assert_in_delta 76.3, instance.score.to_f, 0.01
    assert_equal "rubric", instance.source

    rows = CompetencyAchievementCalculator.new(student: users(:siti), period: academic_periods(:current_period)).call
    assert_equal 75.0, rows.find { |r| r.item == @keterampilan }.percentage
    assert_equal 80.0, rows.find { |r| r.item == @komunikasi }.percentage
    # Sumber ditulis dari nama EVENT-nya, bukan nama template — itu yang
    # dikenali mahasiswa saat menelusuri asal angkanya.
    assert_match "#{event.name} — Penalaran klinis", rows.find { |r| r.item == @keterampilan }.sources.first

    sign_in users(:siti)
    get academic_assessments_path
    assert_match "Capaian per Ranah Kompetensi", response.body
  end

  test "pertanyaan rubrik tanpa pemetaan tidak menyumbang ke peta kompetensi" do
    field = @template.assessment_form_fields.create!(label: "Tanpa peta", field_type: "rating", weight: 1)
    event = assessment_events(:soca_kardio)
    event.update!(assessment_form_template: @template)
    instance = AssessmentInstance.create!(assessment_event: event, student: users(:siti), attempt_number: 1,
                                          max_score: 100, examiner: users(:budi), status: "submitted")

    sign_in users(:budi)
    patch examiner_evaluation_path(instance), params: { answers: { field.id.to_s => "5" } }
    assert_equal "scored", instance.reload.status

    assert_empty CompetencyAchievementCalculator.new(student: users(:siti), period: academic_periods(:current_period)).call
  end

  test "halaman template menampilkan jenjang, bobot, dan pemetaan" do
    @template.assessment_form_fields.create!(label: "Penalaran klinis", field_type: "rubric_level", weight: 2,
                                             competency_item: @keterampilan, options_text: "Kurang | | 1\nBaik | | 2")
    @template.assessment_form_fields.create!(label: "Catatan", field_type: "textarea", required: false)
    sign_in @admin

    get assessment_form_template_path(@template)
    assert_response :success
    assert_match "Kurang (1) · Baik (2)", response.body
    assert_match @keterampilan.title, response.body
    assert_match "1 dipetakan ke ranah kompetensi", response.body
  end
end
