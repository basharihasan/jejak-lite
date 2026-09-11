require "test_helper"

class CompetencyItemTest < ActiveSupport::TestCase
  test "domain? benar untuk simpul tanpa induk" do
    assert competency_items(:domain_klinis).domain?
    assert_not competency_items(:sub_anamnesis).domain?
  end

  test "posisi otomatis mengikuti urutan pembuatan di antara saudara" do
    framework = competency_frameworks(:skdi_ringkas)
    new_domain = framework.competency_items.create!(title: "Landasan Ilmiah Kedokteran")
    assert_equal 3, new_domain.position
  end

  test "menghapus induk juga menghapus anaknya" do
    domain = competency_items(:domain_klinis)
    assert_difference "CompetencyItem.count", -2 do
      domain.destroy
    end
  end

  test "domains pada framework hanya mengembalikan simpul tanpa induk" do
    domains = competency_frameworks(:skdi_ringkas).domains
    assert_includes domains, competency_items(:domain_klinis)
    assert_not_includes domains, competency_items(:sub_anamnesis)
  end
end
