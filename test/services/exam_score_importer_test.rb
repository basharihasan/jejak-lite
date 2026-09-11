require "test_helper"

class ExamScoreImporterTest < ActiveSupport::TestCase
  test "mengimpor baris valid dan mencatat email tak dikenal" do
    csv = <<~CSV
      email,score,exam_date
      #{users(:siti).email},85,#{Date.current}
      tidak.ada@example.com,70,#{Date.current}
    CSV

    result = ExamScoreImporter.new(kind: "osce", name: "OSCE Blok 2", csv_text: csv, imported_by: users(:budi)).call

    assert_equal 1, result.imported_count
    assert_equal [ "tidak.ada@example.com" ], result.unmatched_emails
    assert_equal "osce", result.exam_import.kind
    assert_equal 1, result.exam_import.reload.row_count
  end

  test "max_score default 100 kalau kolom kosong" do
    csv = "email,score,exam_date\n#{users(:siti).email},90,#{Date.current}\n"

    result = ExamScoreImporter.new(kind: "progress_test", name: "PT 1", csv_text: csv, imported_by: users(:budi)).call

    assert_equal 100, result.exam_import.exam_scores.first.max_score.to_i
  end
end
