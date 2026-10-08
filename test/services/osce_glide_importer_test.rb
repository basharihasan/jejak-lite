require "test_helper"

# Impor "Penilaian OSCE" berformat ekspor Glide (data_osce_glide.csv).
class OsceGlideImporterTest < ActiveSupport::TestCase
  HEADER = "rowID,refleksi,emailPenguji,emailYangDiuji,namaPenguji,tanggalEntry,IDSoal,PeriodeUjian," \
           "Anamnesis,PemeriksaanFisik,InterpretasiData,PenegakanDiagnosis,TatalaksanaNonFarmakoterapi," \
           "TatalaksanaFarmakoterapi,KomunikasiDanEdukasiPasien,PerilakuProfesional,halBaik,perluDitingkatkan," \
           "globalRating,kasus,station,emailMahasiswa2\n".freeze

  setup do
    @siti = users(:siti)
    @andi = User.create!(full_name: "Andi", email: "andi@example.com", password: "password123", confirmed_at: Time.current)
    @andi.roles << roles(:mahasiswa)
    @examiner = users(:wati)
    @day1 = 4.days.ago.to_date
    @day2 = 3.days.ago.to_date
  end

  # 02:30 UTC = 09:30 WIB pada hari yang sama.
  def at(date) = "#{date.iso8601}T02:30:00.000Z"

  def import(csv, **options)
    record = GlideImport.create!(importer_key: "osce", filename: "data_osce_glide.csv", imported_by: users(:budi))
    OsceGlideImporter.new(csv_text: csv, glide_import: record, user: users(:budi), **options).call
  end

  def rows
    HEADER +
      "r1,Saya gugup,wati@example.com,siti@example.com,dr. Wati,#{at(@day1)},S01,,3,2,3,3,,,2,3,Anamnesis runtut,Edukasi kurang,Good,Demam dengue,1,\n" \
      "r2,,wati@example.com,siti@example.com,dr. Wati,#{at(@day1)},S02,,1,1,,,,,,,,,Borderline,Hipertensi,2,\n" \
      "r3,,penguji.luar@example.com,,dr. Luar,#{at(@day2)},S01,,3,3,3,3,3,3,3,3,,,Superior,Demam dengue,1,andi@example.com\n" \
      "r4,,wati@example.com,belum.terdaftar@example.com,,#{at(@day2)},S01,,2,2,2,2,2,2,2,2,,,Good,,1,\n" \
      "r5,,wati@example.com,siti@example.com,,#{at(@day2)},S03,,,,,,,,,,,,,,3,\n"
  end

  test "satu event OSCE per hari, 8 dimensi klinis, station tersimpan, nilai dirangkum" do
    result = import(rows)

    assert_equal 5, result.total_rows
    assert_equal 3, result.created_count
    assert_equal({ "mahasiswa_tidak_ditemukan" => 1, "tanpa_nilai" => 1 }, result.skip_reasons)
    assert_equal 0, result.error_count, result.error_messages.inspect
    assert_equal 2, result.created_event_ids.size

    day1 = AssessmentEvent.find_by!(external_code: "OSCE-GLIDE-#{@day1.iso8601}")
    assert_equal "osce", day1.assessment_type
    assert_equal @day1, day1.exam_date
    assert_equal OsceStationScore::DIMENSIONS.values, day1.assessment_dimensions.map(&:name)
    assert(day1.assessment_dimensions.all? { |d| d.max_score == 3 && d.category == "osce_klinis" })

    instance = day1.assessment_instances.find_by!(student: @siti)
    stations = instance.osce_station_scores.to_a
    assert_equal %w[1 2], stations.map(&:station)
    first = stations.first
    assert_equal({ "anamnesis" => 3.0, "pemeriksaanfisik" => 2.0, "interpretasidata" => 3.0, "penegakandiagnosis" => 3.0,
                   "komunikasidanedukasipasien" => 2.0, "perilakuprofesional" => 3.0 }, first.scores)
    assert_in_delta 88.89, first.checklist_score.to_f, 0.01   # 16 / (6 × 3)
    assert_equal "Good", first.global_rating
    assert_equal @examiner, first.examiner
    assert_equal "Anamnesis runtut", first.feedback_keep
    assert_equal "Edukasi kurang", first.feedback_improve
    assert_equal "Saya gugup", first.reflection
    assert_equal "S01", first.question_code
    assert_equal "Demam dengue", first.case_title
    assert_equal @day1, first.assessed_at.to_date

    # Station 2: (1 + 1) / (2 × 3) = 33,33% → rata-rata station (88,89 + 33,33) / 2 = 61,11
    assert_equal "scored", instance.status
    assert_in_delta 61.11, instance.score.to_f, 0.01
    assert_equal @examiner, instance.examiner, "penguji tunggal semua station menjadi penguji percobaan"
    anamnesis = instance.assessment_dimension_scores.joins(:assessment_dimension).find_by!(assessment_dimensions: { code: "anamnesis" })
    assert_equal 2.0, anamnesis.score.to_f, "dimensi = rata-rata station yang menilainya ((3 + 1) / 2)"

    andi = AssessmentEvent.find_by!(external_code: "OSCE-GLIDE-#{@day2.iso8601}").assessment_instances.find_by!(student: @andi)
    assert_equal 100.0, andi.score.to_f, "emailMahasiswa2 dipakai bila emailYangDiuji kosong"
    assert_nil andi.osce_station_scores.first.examiner, "penguji belum terdaftar tetap dicatat namanya"
    assert_equal "dr. Luar", andi.osce_station_scores.first.details["nama_penguji"]
  end

  test "$rowID yang sudah diimpor dilewati saat unggah ulang" do
    import(rows)
    again = import(rows)

    assert_equal 0, again.created_count
    assert_equal 3, again.skip_reasons["sudah_diimpor"]
    assert_equal 3, OsceStationScore.count
    assert_empty again.created_event_ids
  end

  test "baris tanpa $rowID dicegah kembar lewat mahasiswa + soal + penguji + hari" do
    csv = HEADER + ",,wati@example.com,siti@example.com,,#{at(@day1)},S01,,3,3,3,3,3,3,3,3,,,Good,,1,\n"
    import(csv + csv.lines.last)
    again = import(csv)

    assert_equal 1, OsceStationScore.count
    assert_equal 1, again.skip_reasons["station_sudah_ada"]
  end

  test "nilai di luar skala 0–3 dan tanggal tidak wajar menjadi galat baris" do
    csv = HEADER +
          "x1,,,siti@example.com,,#{at(@day1)},S01,,4,3,,,,,,,,,Good,,1,\n" \
          "x2,,,siti@example.com,,2116-01-01T00:00:00.000Z,S01,,3,3,,,,,,,,,Good,,1,\n"
    result = import(csv)

    assert_equal 2, result.error_count
    assert_match "di luar skala", result.error_messages.first
    assert_match "tidak wajar", result.error_messages.last
    assert_equal 0, OsceStationScore.count
    assert_empty result.created_event_ids, "event tidak dibuat untuk baris yang gagal"
  end

  test "event tujuan pilihan admin menampung seluruh berkas" do
    target = assessment_events(:cbt_blok).dup.tap { |e| e.update!(name: "OSCE Akhir Blok", assessment_type: "osce", external_code: nil) }
    result = import(rows, target_event: target)

    assert_empty result.created_event_ids
    assert_equal 3, target.osce_station_scores.count
    assert_equal 2, target.assessment_instances.count
  end

  test "nilai OSCE dari sumber lain tidak ditimpa station Glide" do
    target = assessment_events(:cbt_blok).dup.tap { |e| e.update!(name: "OSCE Manual", assessment_type: "osce", external_code: nil) }
    manual = AssessmentInstance.create!(assessment_event: target, student: @siti, max_score: 100, score: 77, status: "scored")

    result = import(rows, target_event: target)
    assert_equal 2, result.skip_reasons["nilai_lain_sudah_ada"]
    assert_equal 77.0, manual.reload.score.to_f
    assert_equal 0, manual.osce_station_scores.count
  end

  test "berkas bukan ekspor Penilaian OSCE ditolak" do
    result = import("email,total_score\nsiti@example.com,80\n")
    assert_match "Kolom dimensi OSCE", result.error_messages.first
  end

  test "rollback membuang station, peserta, dan event yang dibuatnya" do
    result = import(rows)
    assert result.rollback!(users(:budi))

    assert_equal 0, OsceStationScore.count
    assert_equal 0, AssessmentInstance.where(id: result.created_instance_ids).count
    assert_equal 0, AssessmentEvent.where(id: result.created_event_ids).count
    assert_equal "rolled_back", result.reload.status
  end

  test "rollback unggahan kedua mempertahankan station unggahan pertama dan merangkum ulang" do
    first = import(HEADER + "a1,,wati@example.com,siti@example.com,,#{at(@day1)},S01,,3,3,3,3,3,3,3,3,,,Superior,,1,\n")
    second = import(HEADER + "a2,,wati@example.com,siti@example.com,,#{at(@day1)},S02,,0,0,0,0,0,0,0,0,,,Fail,,2,\n")
    instance = AssessmentInstance.find(first.created_instance_ids.first)
    assert_equal 50.0, instance.reload.score.to_f
    assert_empty second.created_instance_ids, "unggahan kedua menambah station ke peserta yang sama"

    second.rollback!(users(:budi))
    assert_equal 100.0, instance.reload.score.to_f
    assert_equal 1, instance.osce_station_scores.count
    assert AssessmentEvent.exists?(first.created_event_ids.first)
  end
end
