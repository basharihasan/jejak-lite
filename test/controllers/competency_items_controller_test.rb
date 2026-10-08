require "test_helper"

class CompetencyItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak boleh menambah simpul kompetensi" do
    sign_in users(:siti)
    framework = competency_frameworks(:skdi_ringkas)

    assert_no_difference "CompetencyItem.count" do
      post competency_framework_competency_items_path(framework), params: { competency_item: { title: "Ranah Baru" } }
    end
    assert_response :redirect
  end

  test "admin bisa menambah ranah baru" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    framework = competency_frameworks(:skdi_ringkas)

    assert_difference "CompetencyItem.count", 1 do
      post competency_framework_competency_items_path(framework), params: { competency_item: { title: "Ranah Baru" } }
    end
  end

  test "admin bisa menambah sub-kompetensi di bawah ranah" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    framework = competency_frameworks(:skdi_ringkas)
    domain = competency_items(:domain_klinis)

    assert_difference "CompetencyItem.count", 1 do
      post competency_framework_competency_items_path(framework),
        params: { competency_item: { title: "Sub Baru", parent_id: domain.id } }
    end
    assert_equal domain, CompetencyItem.last.parent
  end

  test "admin bisa menghapus simpul kompetensi" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    framework = competency_frameworks(:skdi_ringkas)
    sub = competency_items(:sub_anamnesis)

    assert_difference "CompetencyItem.count", -1 do
      delete competency_framework_competency_item_path(framework, sub)
    end
  end

  test "simpul yang dipakai Peta EPA mahasiswa tidak bisa dihapus beserta sub-kompetensinya" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    framework = competency_frameworks(:skdi_ringkas)
    EntrustmentDecision.decide!(student: users(:siti), competency_item: competency_items(:domain_klinis), level: 3,
                                justification: "Supervisi tidak langsung.", decided_by: users(:budi))

    assert_no_difference "CompetencyItem.count" do
      delete competency_framework_competency_item_path(framework, competency_items(:domain_klinis))
    end
    assert_redirected_to competency_framework_path(framework)
    assert_match "Peta EPA", flash[:alert]

    assert_no_difference "CompetencyFramework.count" do
      delete competency_framework_path(framework)
    end
    assert_match "Peta EPA", flash[:alert]
  end

  test "menghapus simpul melepas pemetaan dimensi ujian dan pertanyaan rubrik, bukan galat" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    framework = competency_frameworks(:skdi_ringkas)
    sub = competency_items(:sub_anamnesis)
    dimension = assessment_events(:cbt_blok).assessment_dimensions.create!(name: "Anamnesis", max_score: 10, competency_item: sub)
    template = AssessmentFormTemplate.create!(name: "Rubrik Uji")
    field = template.assessment_form_fields.create!(label: "Anamnesis", field_type: "rating", competency_item: sub)

    assert_difference "CompetencyItem.count", -1 do
      delete competency_framework_competency_item_path(framework, sub)
    end
    assert_nil dimension.reload.competency_item_id
    assert_nil field.reload.competency_item_id
  end
end
