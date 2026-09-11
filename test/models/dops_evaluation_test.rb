require "test_helper"

class DopsEvaluationTest < ActiveSupport::TestCase
  test "komunikasi, profesionalisme, dan penilaian global wajib diisi, tidak boleh N/A" do
    dops = DopsEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Jahit Luka", evaluated_at: Date.current, scores: { "persiapan" => 5 }
    )

    assert_not dops.valid?
    assert dops.errors[:scores].any? { |m| m.include?("Komunikasi dengan Pasien") }
    assert dops.errors[:scores].any? { |m| m.include?("Profesionalisme") }
    assert dops.errors[:scores].any? { |m| m.include?("Penilaian Global") }
  end

  test "dimensi non-wajib boleh N/A (nil)" do
    dops = DopsEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Jahit Luka", evaluated_at: Date.current,
      scores: { "komunikasi" => 7, "profesionalisme" => 8, "penilaian_global" => 7 }
    )

    assert dops.valid?
  end

  test "skor harus 1-9" do
    dops = DopsEvaluation.new(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Jahit Luka", evaluated_at: Date.current,
      scores: { "komunikasi" => 7, "profesionalisme" => 15, "penilaian_global" => 7 }
    )

    assert_not dops.valid?
  end

  test "average_score menghitung rata-rata dari skor yang terisi saja" do
    dops = dops_evaluations(:dops_siti_infus)
    expected = [ 7, 7, 6, 6, 8, 7, 6, 7, 8, 7 ].sum / 10.0
    assert_equal expected.round(1), dops.average_score
  end

  test "membuat evaluasi berstatus submitted (default) langsung mengirim notifikasi" do
    assert_difference "Notification.count", 1 do
      DopsEvaluation.create!(
        student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
        procedure_name: "Pungsi Vena", evaluated_at: Date.current,
        scores: { "komunikasi" => 6, "profesionalisme" => 7, "penilaian_global" => 6 }
      )
    end

    assert_equal users(:siti), Notification.last.recipient
  end

  test "evaluasi draft tidak mengirim notifikasi sampai disubmit" do
    dops = nil
    assert_no_difference "Notification.count" do
      dops = DopsEvaluation.create!(
        student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
        procedure_name: "Pungsi Vena", evaluated_at: Date.current, status: "draft",
        scores: { "komunikasi" => 6, "profesionalisme" => 7, "penilaian_global" => 6 }
      )
    end

    assert dops.draft?

    assert_difference "Notification.count", 1 do
      dops.submit!
    end
    assert dops.submitted?
  end

  test "avg_dimension_scores menghitung rata-rata per dimensi lintas evaluasi" do
    averages = DopsEvaluation.avg_dimension_scores(DopsEvaluation.where(id: dops_evaluations(:dops_siti_infus).id))
    assert_equal 7.0, averages["persiapan"]
    assert_equal 7.0, averages["persetujuan_tindakan"]
  end
end
