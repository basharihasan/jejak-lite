require "application_system_test_case"

# Regresi: grafik tren Evaluasi Akademik (line_chart bersumbu tanggal) gagal
# dirender di produksi karena Chart.js dimuat tanpa adapter tanggal —
# "Check that a complete date adapter is provided".
class ExamScoresChartTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  test "grafik tren nilai pada Evaluasi Akademik berhasil dirender" do
    # Grafik tren baru tampil bila satu tipe punya lebih dari satu nilai.
    second = AssessmentEvent.create!(name: "CBT Kedua", assessment_type: "cbt", status: "published", max_score: 100,
                                     academic_period: academic_periods(:current_period), exam_date: 2.days.ago.to_date)
    AssessmentInstance.create!(assessment_event: second, student: users(:siti), score: 70, max_score: 100,
                               status: "scored", scored_at: 2.days.ago)

    sign_in users(:siti)
    visit exam_scores_path

    assert_selector "canvas"
    rendered = page.evaluate_script(<<~JS)
      Object.values(window.Chartkick ? Chartkick.charts : {}).length > 0 &&
        Object.values(Chartkick.charts).every((chart) => chart.getChartObject())
    JS
    assert rendered, "Ada grafik Chartkick yang gagal dibuat"
  end
end
