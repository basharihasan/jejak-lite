require "test_helper"

class GlideCsvTest < ActiveSupport::TestCase
  test "tanggal angka dan ISO" do
    assert_equal Time.zone.local(2026, 6, 6), GlideCsv.time("06/06/2026")
    assert_equal Time.zone.local(2026, 6, 6), GlideCsv.time("2026-06-06")
    assert_nil GlideCsv.time(" ")
  end

  test "tanggal bernama bulan: Indonesia, Inggris, singkatan, salah ketik, nama hari" do
    assert_equal Time.zone.local(2026, 9, 9), GlideCsv.time("9 Septermber 2026")
    assert_equal Time.zone.local(2026, 8, 17), GlideCsv.time("17 Agustus 2026")
    assert_equal Time.zone.local(2026, 12, 1), GlideCsv.time("1 Des 2026")
    assert_equal Time.zone.local(2026, 5, 6), GlideCsv.time("6 May 2026")
    assert_equal Time.zone.local(2026, 10, 24, 8, 30), GlideCsv.time("Sabtu, 24 Oktober 2026 08:30")
  end

  test "bulan tak dikenal atau teks bebas tidak terbaca" do
    assert_equal :invalid, GlideCsv.time("9 Foo 2026")
    assert_equal :invalid, GlideCsv.time("minggu depan")
  end
end
