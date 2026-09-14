require "test_helper"

# Fase 26 — Pilar C: Assessment Matrix per Learning Unit dan kurva persentil
# kohort (PSSK + PSPD) di halaman Analisis Capaian Pembelajaran.
class CompetencyMappingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @period = academic_periods(:current_period)
    @unit = LearningUnit.create!(name: "Blok Kardiovaskular", code: "BLK-KV",
                                 study_program: study_programs(:sarjana_kedokteran), academic_period: @period, credits: 6)
  end

  test "admin menyusun Assessment Matrix; total bobot ditandai lengkap/belum" do
    sign_in @admin
    get admin_learning_units_path
    assert_response :success

    post add_mapping_admin_learning_unit_path(@unit), params: { assessment_event_id: assessment_events(:cbt_blok).id, weight: 60 }
    assert_redirected_to admin_learning_unit_path(@unit)
    assert_equal 60.0, @unit.reload.total_weight
    assert_not @unit.weights_complete?

    post add_mapping_admin_learning_unit_path(@unit), params: { assessment_event_id: assessment_events(:soca_kardio).id, weight: 40 }
    assert @unit.reload.weights_complete?

    # Event yang sama tidak boleh dipetakan dua kali
    assert_no_difference "AssessmentMapping.count" do
      post add_mapping_admin_learning_unit_path(@unit), params: { assessment_event_id: assessment_events(:cbt_blok).id, weight: 10 }
    end

    get admin_learning_unit_path(@unit)
    assert_response :success
    assert_match "100.0%", response.body

    mapping = @unit.assessment_mappings.find_by(assessment_event: assessment_events(:soca_kardio))
    assert_difference "AssessmentMapping.count", -1 do
      delete remove_mapping_admin_learning_unit_path(@unit, mapping_id: mapping.id)
    end
  end

  test "nilai unit = rata-rata terbobot komponen yang sudah dinilai saja" do
    @unit.assessment_mappings.create!(assessment_event: assessment_events(:cbt_blok), weight: 60)
    @unit.assessment_mappings.create!(assessment_event: assessment_events(:soca_kardio), weight: 40)

    # CBT siti = 62% (fixture). SOCA belum dinilai → bobotnya tidak ikut.
    score = @unit.score_for(users(:siti))
    assert_equal 62.0, score[:percentage]
    assert_equal 60.0, score[:weight_covered]

    # Setelah SOCA dinilai 90 → (62*60 + 90*40) / 100 = 73.2
    AssessmentInstance.create!(assessment_event: assessment_events(:soca_kardio), student: users(:siti),
                               attempt_number: 1, status: "scored", score: 90, max_score: 100, scored_at: Time.current)
    score = @unit.reload.score_for(users(:siti))
    assert_equal 73.2, score[:percentage]
    assert_equal 100.0, score[:weight_covered]
  end

  test "percobaan tertinggi mewakili event dalam perhitungan unit" do
    @unit.assessment_mappings.create!(assessment_event: assessment_events(:cbt_blok), weight: 100)
    AssessmentInstance.create!(assessment_event: assessment_events(:cbt_blok), student: users(:siti),
                               attempt_number: 2, status: "scored", score: 88, max_score: 100, scored_at: Time.current)
    assert_equal 88.0, @unit.score_for(users(:siti))[:percentage]
  end

  test "mahasiswa melihat nilai blok di Analisis Capaian Pembelajaran" do
    @unit.assessment_mappings.create!(assessment_event: assessment_events(:cbt_blok), weight: 100)
    sign_in users(:siti)
    get academic_assessments_path

    assert_response :success
    assert_match "Nilai Blok / Modul", response.body
    assert_match "Blok Kardiovaskular", response.body
    assert_match "62.0%", response.body
  end

  test "unit prodi lain tidak tampil bagi mahasiswa" do
    @unit.update!(study_program: study_programs(:profesi_dokter))
    @unit.assessment_mappings.create!(assessment_event: assessment_events(:cbt_blok), weight: 100)
    sign_in users(:siti)
    get academic_assessments_path
    # Kode unit dipakai sebagai penanda: nama event fixture kebetulan juga
    # mengandung frasa "Blok Kardiovaskular".
    assert_no_match "BLK-KV", response.body
    assert_no_match "Nilai Blok / Modul", response.body
  end

  # ── Kurva persentil kohort ──
  test "persentil disembunyikan bila kohort kurang dari batas minimum" do
    rows = CohortPercentileCalculator.new(student: users(:siti), period: @period).call
    assert_empty rows # fixture hanya 1 nilai CBT
  end

  test "persentil dihitung per tipe asesmen dengan kohort gabungan PSSK+PSPD" do
    peers = 4.times.map do |i|
      u = User.create!(full_name: "Peer #{i}", email: "peer#{i}@example.com", password: "password123", confirmed_at: Time.current,
                       study_program: i.even? ? study_programs(:sarjana_kedokteran) : study_programs(:profesi_dokter))
      u.roles << roles(:mahasiswa)
      AssessmentInstance.create!(assessment_event: assessment_events(:cbt_blok), student: u, attempt_number: 1,
                                 status: "scored", score: [ 40, 50, 70, 90 ][i], max_score: 100, scored_at: Time.current)
      u
    end
    assert_equal 4, peers.size

    rows = CohortPercentileCalculator.new(student: users(:siti), period: @period).call
    cbt = rows.find { |r| r[:type] == "cbt" }
    assert_equal 5, cbt[:cohort_size] # 4 peer + siti, lintas kedua prodi
    assert_equal 62.0, cbt[:my_percentage]
    assert_equal 50, cbt[:percentile]  # 2 di bawah, 2 di atas
    # 5 nilai terurut [40,50,62,70,90]; P10 = interpolasi 0,4 antara 40 dan 50.
    assert_equal 44.0, cbt[:bands][10].round(1)
    assert_equal 62.0, cbt[:bands][50]

    sign_in users(:siti)
    get academic_assessments_path
    assert_match "Posisi terhadap Kohort", response.body
    assert_match "P50", response.body
  end

  test "nilai dari periode lain tidak ikut kohort" do
    other = AcademicPeriod.create!(name: "Periode Lampau", start_date: 2.years.ago.to_date, end_date: 1.year.ago.to_date)
    event = AssessmentEvent.create!(name: "CBT Lampau", assessment_type: "cbt", academic_period: other, status: "published")
    3.times do |i|
      u = User.create!(full_name: "Lama #{i}", email: "lama#{i}@example.com", password: "password123", confirmed_at: Time.current,
                       study_program: study_programs(:sarjana_kedokteran))
      u.roles << roles(:mahasiswa)
      AssessmentInstance.create!(assessment_event: event, student: u, attempt_number: 1, status: "scored", score: 80, max_score: 100, scored_at: Time.current)
    end
    assert_empty CohortPercentileCalculator.new(student: users(:siti), period: @period).call
  end

  test "bukan admin/kaprodi ditolak mengelola Learning Unit" do
    sign_in users(:siti)
    get admin_learning_units_path
    assert_redirected_to dashboard_path
  end
end
