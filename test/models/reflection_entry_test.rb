require "test_helper"

class ReflectionEntryTest < ActiveSupport::TestCase
  test "wajib punya entry_date dan content" do
    entry = ReflectionEntry.new(user: users(:siti))
    assert_not entry.valid?
    assert_includes entry.errors[:entry_date], "tidak boleh kosong"
    assert_includes entry.errors[:content], "tidak boleh kosong"
  end

  test "bisa ditautkan opsional ke activity_log atau clinical_case" do
    entry = ReflectionEntry.new(
      user: users(:siti), entry_date: Date.current, content: "Refleksi",
      activity_log: activity_logs(:kegiatan_siti)
    )
    assert entry.valid?
    assert_equal activity_logs(:kegiatan_siti), entry.activity_log
  end
end
