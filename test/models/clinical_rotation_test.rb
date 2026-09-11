require "test_helper"

class ClinicalRotationTest < ActiveSupport::TestCase
  test "status berlangsung/akan_datang/selesai dihitung dari tanggal" do
    assert_equal "berlangsung", clinical_rotations(:ongoing_rotation_siti).status
    assert_equal "akan_datang", clinical_rotations(:upcoming_rotation_siti).status
  end

  test "end_date tidak boleh sebelum start_date" do
    rotasi = ClinicalRotation.new(
      user: users(:siti), academic_period: academic_periods(:current_period),
      station_name: "Anak", start_date: Date.current, end_date: 1.day.ago.to_date
    )

    assert_not rotasi.valid?
    assert_includes rotasi.errors[:end_date], "harus setelah atau sama dengan tanggal mulai"
  end

  test "scope ongoing/upcoming menyaring dengan benar" do
    assert_includes ClinicalRotation.ongoing, clinical_rotations(:ongoing_rotation_siti)
    assert_not_includes ClinicalRotation.ongoing, clinical_rotations(:upcoming_rotation_siti)
    assert_includes ClinicalRotation.upcoming, clinical_rotations(:upcoming_rotation_siti)
  end
end
