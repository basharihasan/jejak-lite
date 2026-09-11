require "test_helper"

class MiniCexEvaluationTest < ActiveSupport::TestCase
  test "komunikasi dan profesionalisme wajib diisi, tidak boleh N/A" do
    mini_cex = MiniCexEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      case_description: "Nyeri dada", evaluated_at: Date.current, scores: { "anamnesis" => 5 },
      global_rating: "performed"
    )

    assert_not mini_cex.valid?
    assert mini_cex.errors[:scores].any? { |m| m.include?("Komunikasi") }
    assert mini_cex.errors[:scores].any? { |m| m.include?("Profesionalisme") }
  end

  test "global_rating wajib diisi salah satu opsi" do
    mini_cex = MiniCexEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      case_description: "Nyeri dada", evaluated_at: Date.current,
      scores: { "komunikasi" => 7, "profesionalisme" => 8 }
    )

    assert_not mini_cex.valid?
    assert mini_cex.errors[:global_rating].present?

    mini_cex.global_rating = "performed"
    assert mini_cex.valid?
  end

  test "average_score menghitung rata-rata dari skor yang terisi saja" do
    mini_cex = mini_cex_evaluations(:minicex_siti_demam)
    expected = [ 7, 6, 7, 6, 8, 7 ].sum / 6.0
    assert_equal expected.round(1), mini_cex.average_score
  end

  test "global_rating_label mengembalikan label yang bisa dibaca" do
    mini_cex = mini_cex_evaluations(:minicex_siti_demam)
    assert_equal "Sesuai Harapan", mini_cex.global_rating_label
  end

  test "evaluasi draft tidak mengirim notifikasi sampai disubmit" do
    mini_cex = nil
    assert_no_difference "Notification.count" do
      mini_cex = MiniCexEvaluation.create!(
        student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
        case_description: "Nyeri dada", evaluated_at: Date.current, status: "draft",
        scores: { "komunikasi" => 7, "profesionalisme" => 8 }, global_rating: "performed"
      )
    end

    assert mini_cex.draft?

    assert_difference "Notification.count", 1 do
      mini_cex.submit!
    end
    assert mini_cex.submitted?
  end
end
