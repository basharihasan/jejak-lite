require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  test "wajib punya title, activity_date, category valid" do
    log = ActivityLog.new(user: users(:budi))
    assert_not log.valid?
    assert_includes log.errors[:title], "tidak boleh kosong"
    assert_includes log.errors[:activity_date], "tidak boleh kosong"
    assert_includes log.errors[:category], "tidak termasuk"
  end

  test "category_label menerjemahkan kode ke label" do
    assert_equal "Klinis", activity_logs(:jaga_igd).category_label
    assert_equal "Non-Klinis", activity_logs(:penyuluhan_stunting).category_label
  end

  test "ensure_patient_code! membuat kode sekali dan memakainya ulang" do
    log = activity_logs(:jaga_igd)
    assert_nil log.patient_code

    code = log.ensure_patient_code!
    assert_match(/\AP-[A-Z0-9]{8}\z/, code)
    assert_equal code, log.ensure_patient_code!
  end

  test "scope klinis/non_klinis menyaring berdasar kategori" do
    assert_includes ActivityLog.klinis, activity_logs(:jaga_igd)
    assert_not_includes ActivityLog.klinis, activity_logs(:penyuluhan_stunting)
  end

  test "bisa ditautkan ke beberapa simpul kompetensi" do
    log = activity_logs(:jaga_igd)
    log.competency_item_ids = [ competency_items(:domain_klinis).id, competency_items(:sub_anamnesis).id ]

    assert_equal 2, log.competency_items.count
    assert_includes ActivityLog.tagged_with(competency_items(:domain_klinis).id), log
    assert_not_includes ActivityLog.tagged_with(competency_items(:domain_komunikasi).id), log
  end

  test "delivery_mode_label menerjemahkan kode ke label" do
    log = activity_logs(:jaga_igd)
    log.delivery_mode = "daring"
    assert_equal "Daring", log.delivery_mode_label
  end
end
