require "test_helper"

class DopsEvaluationTest < ActiveSupport::TestCase
  test "komunikasi dan profesionalisme wajib diisi, tidak boleh N/A" do
    dops = DopsEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Jahit Luka", evaluated_at: Date.current, scores: { "persiapan" => 5 }
    )

    assert_not dops.valid?
    assert dops.errors[:scores].any? { |m| m.include?("Komunikasi dengan Pasien") }
    assert dops.errors[:scores].any? { |m| m.include?("Profesionalisme") }
  end

  test "dimensi non-wajib boleh N/A (nil)" do
    dops = DopsEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Jahit Luka", evaluated_at: Date.current,
      scores: { "komunikasi" => 7, "profesionalisme" => 8 }
    )

    assert dops.valid?
  end

  test "skor harus 1-9" do
    dops = DopsEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Jahit Luka", evaluated_at: Date.current,
      scores: { "komunikasi" => 7, "profesionalisme" => 15 }
    )

    assert_not dops.valid?
  end

  test "average_score menghitung rata-rata dari skor yang terisi saja" do
    dops = dops_evaluations(:dops_siti_infus)
    expected = [ 7, 6, 8, 7, 8, 6 ].sum / 6.0
    assert_equal expected.round(1), dops.average_score
  end

  test "membuat evaluasi mengirim notifikasi ke mahasiswa" do
    assert_difference "Notification.count", 1 do
      DopsEvaluation.create!(
        student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
        procedure_name: "Pungsi Vena", evaluated_at: Date.current,
        scores: { "komunikasi" => 6, "profesionalisme" => 7 }
      )
    end

    assert_equal users(:siti), Notification.last.recipient
  end
end
