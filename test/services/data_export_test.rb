require "test_helper"
require "csv"

class DataExportTest < ActiveSupport::TestCase
  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @kaprodi = users(:dedi) # kaprodi Sarjana Kedokteran
  end

  def rows_for(key, viewer: @admin, **filters)
    export = DataExport.new(key, viewer: viewer, **filters)
    rows = CSV.parse(export.to_csv.delete_prefix("﻿"), headers: true)
    assert_equal export.count, export.row_count, "pratinjau jumlah baris #{key} harus sama dengan isi berkas"
    rows
  end

  test "dataset khusus admin dan kaprodi tanpa prodi ditolak" do
    assert_not DataExport.allowed?(users(:wati))
    assert_raises(DataExport::AccessDenied) { DataExport.new("users", viewer: @kaprodi) }

    @kaprodi.update!(study_program: nil)
    assert_raises(DataExport::AccessDenied) { DataExport.new("students", viewer: @kaprodi) }
  end

  test "setiap dataset menghasilkan baris selebar header-nya" do
    DataExport::DATASETS.each_value do |dataset|
      export = DataExport.new(dataset.key, viewer: @admin)
      table = CSV.parse(export.to_csv.delete_prefix("﻿"))
      assert_equal dataset.headers, table.first, dataset.key
      assert table.drop(1).all? { |row| row.size == dataset.headers.size }, "#{dataset.key}: lebar baris tidak sama dengan header"
    end
  end

  test "rekap per mahasiswa menghitung capaian siti" do
    row = rows_for("student_summary").find { |r| r["Email"] == "siti@example.com" }

    assert_equal "2", row["Kegiatan"]
    assert_equal "1", row["Kasus Diajukan"] # draf tidak dihitung
    assert_equal "0", row["Kasus Terverifikasi"]
    assert_equal "1", row["DOPS Terkirim"]
    assert_equal "6.9", row["Rata-rata DOPS"]
    assert_equal "Berjalan", row["Status Tugas Akhir"]
  end

  test "rentang tanggal menyaring rotasi yang bersinggungan" do
    stations = rows_for("clinical_rotations", from: 15.days.from_now.to_date).map { |r| r["Stase / Blok Klinis"] }
    assert_equal [ "Bedah" ], stations

    period = academic_periods(:current_period)
    assert_equal 3, rows_for("clinical_rotations", academic_period_id: period.id).size
  end

  test "periode tanpa kolom periode menjadi rentang tanggal" do
    period = academic_periods(:current_period)
    period.update!(start_date: 5.days.ago.to_date, end_date: 2.days.ago.to_date)

    titles = rows_for("activity_logs", academic_period_id: period.id).map { |r| r["Topik"] }
    assert_equal [ "Jaga IGD", "Tutorial Skenario Nyeri Dada" ], titles
  end
end
