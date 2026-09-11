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
end
