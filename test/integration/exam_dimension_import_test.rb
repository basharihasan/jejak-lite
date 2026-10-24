require "test_helper"

# Impor hasil ujian CBT & OSCE per dimensi (mata uji / station) beserta
# pemetaan dimensi → ranah kompetensi yang mengisi Peta Kompetensi.
class ExamDimensionImportTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @period = academic_periods(:current_period)
    @framework = competency_frameworks(:skdi_ringkas)
    @keterampilan = @framework.domains.find { |d| d.title.include?("Keterampilan") } || @framework.domains.first
    @komunikasi = (@framework.domains - [ @keterampilan ]).first

    @cbt = assessment_events(:cbt_blok)
    # Impor CBT lazimnya menimpa nilai yang sama, bukan menumpuk percobaan.
    @cbt.update!(allow_multiple_attempts: false)
    @penalaran = @cbt.assessment_dimensions.create!(name: "Penalaran Klinis", code: "PK", max_score: 40, weight: 2, competency_item: @keterampilan)
    @literasi = @cbt.assessment_dimensions.create!(name: "Literasi Sains", code: "LS", max_score: 20, weight: 1, competency_item: @komunikasi)
  end

  # ── Impor per dimensi ──
  test "impor CBT per mata uji menghitung total terbobot dan menyimpan nilai per dimensi" do
    sign_in @admin
    csv = "email,Penalaran Klinis,Literasi Sains\nsiti@example.com,30,10\n"

    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: csv, mapping: { email: "email" },
      dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis", @literasi.id.to_s => "Literasi Sains" }
    }
    assert_response :success
    assert_match "2 nilai per dimensi", response.body

    instance = AssessmentInstance.find_by!(assessment_event: @cbt, student: users(:siti), attempt_number: 1)
    assert_equal 2, instance.assessment_dimension_scores.count
    # PK 30/40 = 75% bobot 2 · LS 10/20 = 50% bobot 1 → (75*2 + 50)/3 = 66,67% × maks 100
    assert_in_delta 66.67, instance.score.to_f, 0.02
    assert_equal "import", instance.source
    assert_equal "scored", instance.status
  end

  test "kolom skor total yang dipetakan mengalahkan perhitungan dimensi" do
    sign_in @admin
    csv = "email,total,Penalaran Klinis\nsiti@example.com,88,30\n"

    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: csv, mapping: { email: "email", score: "total" },
      dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis" }
    }
    instance = AssessmentInstance.find_by!(assessment_event: @cbt, student: users(:siti), attempt_number: 1)
    assert_equal 88.0, instance.score.to_f
    assert_equal 1, instance.assessment_dimension_scores.count, "nilai dimensi tetap disimpan untuk peta kompetensi"
  end

  test "nilai dimensi di atas skala dilaporkan, bukan disimpan diam-diam" do
    sign_in @admin
    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: "email,Penalaran Klinis\nsiti@example.com,99\n",
      mapping: { email: "email" }, dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis" }
    }
    assert_match "melebihi nilai maksimum", response.body
    assert_equal 0, AssessmentDimensionScore.joins(:assessment_dimension).where(assessment_dimensions: { id: @penalaran.id }).count
  end

  test "impor tanpa kolom skor maupun dimensi ditolak dengan pesan" do
    sign_in @admin
    post import_create_admin_assessment_event_path(@cbt), params: { csv_text: "email\nsiti@example.com\n", mapping: { email: "email" } }
    assert_match "Petakan kolom skor total, atau minimal satu kolom dimensi", response.body
  end

  test "impor ulang memperbarui nilai dimensi yang sama, tidak menggandakan" do
    sign_in @admin
    2.times do |i|
      post import_create_admin_assessment_event_path(@cbt), params: {
        csv_text: "email,Penalaran Klinis\nsiti@example.com,#{20 + i * 10}\n",
        mapping: { email: "email" }, dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis" }
      }
    end
    instance = AssessmentInstance.find_by!(assessment_event: @cbt, student: users(:siti), attempt_number: 1)
    assert_equal 1, instance.assessment_dimension_scores.count
    assert_equal 30.0, instance.assessment_dimension_scores.first.score.to_f
  end

  test "langkah pemetaan menawarkan kolom dimensi dan kolom sisa untuk dijadikan dimensi baru" do
    sign_in @admin
    csv = "email,Penalaran Klinis,Station Baru\nsiti@example.com,30,70\n"
    post import_preview_admin_assessment_event_path(@cbt),
         params: { file: Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "n.csv") }

    assert_response :success
    assert_select "select[name=?]", "dimension_mapping[#{@penalaran.id}]"
    assert_select "select[name=?] option[selected][value=?]", "dimension_mapping[#{@penalaran.id}]", "Penalaran Klinis"
    assert_select "input[name=?][value=?]", "create_dimensions[]", "Station Baru"
  end

  test "kolom sisa dapat langsung dijadikan dimensi baru saat impor" do
    sign_in @admin
    assert_difference "AssessmentDimension.count", 1 do
      post import_create_admin_assessment_event_path(@cbt), params: {
        csv_text: "email,Station Baru\nsiti@example.com,70\n",
        mapping: { email: "email" }, create_dimensions: [ "Station Baru" ]
      }
    end
    baru = @cbt.assessment_dimensions.find_by!(name: "Station Baru")
    assert_equal 100, baru.max_score.to_i
    assert_nil baru.competency_item_id, "dimensi baru belum dipetakan — admin memetakannya setelah impor"
  end

  # ── OSCE: satu kolom per station ──
  test "impor OSCE per station" do
    osce = AssessmentEvent.create!(name: "OSCE Akhir Blok", assessment_type: "osce", academic_period: @period,
                                   status: "published", max_score: 100)
    s1 = osce.assessment_dimensions.create!(name: "Station 1 — Anamnesis", code: "ST1", max_score: 10, competency_item: @keterampilan)
    s2 = osce.assessment_dimensions.create!(name: "Station 2 — Komunikasi", code: "ST2", max_score: 10, competency_item: @komunikasi)
    sign_in @admin

    post import_create_admin_assessment_event_path(osce), params: {
      csv_text: "email;ST1;ST2\nsiti@example.com;8;6\n",
      mapping: { email: "email" }, dimension_mapping: { s1.id.to_s => "ST1", s2.id.to_s => "ST2" }
    }
    instance = AssessmentInstance.find_by!(assessment_event: osce, student: users(:siti))
    assert_equal 70.0, instance.score.to_f # (80% + 60%) / 2
    assert_equal 2, instance.assessment_dimension_scores.count
  end

  # ── Pemetaan dimensi → kompetensi ──
  test "admin mengelola dimensi dan memetakannya ke ranah kompetensi" do
    sign_in @admin

    get admin_assessment_event_path(@cbt, tab: "dimensi")
    assert_response :success
    assert_match "Penalaran Klinis", response.body
    assert_match @keterampilan.title, response.body

    assert_difference "AssessmentDimension.count", 1 do
      post admin_assessment_event_assessment_dimensions_path(@cbt), params: {
        assessment_dimension: { name: "Etika Profesi", max_score: 15, weight: 1 }
      }
    end
    etika = @cbt.assessment_dimensions.find_by!(name: "Etika Profesi")
    assert_not etika.mapped?

    patch bulk_map_admin_assessment_event_assessment_dimensions_path(@cbt), params: {
      competency_item_ids: { etika.id.to_s => @komunikasi.id.to_s, @penalaran.id.to_s => "" }
    }
    assert_equal @komunikasi, etika.reload.competency_item
    assert_nil @penalaran.reload.competency_item_id, "pemetaan juga bisa dilepas"
  end

  test "nama dimensi tidak boleh kembar dalam satu event" do
    sign_in @admin
    assert_no_difference "AssessmentDimension.count" do
      post admin_assessment_event_assessment_dimensions_path(@cbt), params: { assessment_dimension: { name: "Penalaran Klinis" } }
    end
    follow_redirect!
    assert_match "sudah ada pada event ini", response.body
  end

  test "dimensi yang sudah punya nilai tidak bisa dihapus" do
    sign_in @admin
    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: "email,Penalaran Klinis\nsiti@example.com,30\n",
      mapping: { email: "email" }, dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis" }
    }
    assert_no_difference "AssessmentDimension.count" do
      delete admin_assessment_dimension_path(@penalaran)
    end
    follow_redirect!
    assert_match "sudah punya nilai mahasiswa", response.body
  end

  test "bukan admin ditolak mengelola dimensi" do
    sign_in users(:siti)
    post admin_assessment_event_assessment_dimensions_path(@cbt), params: { assessment_dimension: { name: "X" } }
    assert_redirected_to dashboard_path
  end

  # ── Peta Kompetensi terisi dari dimensi ──
  test "capaian per ranah kompetensi dihitung dari dimensi yang dipetakan" do
    sign_in @admin
    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: "email,Penalaran Klinis,Literasi Sains\nsiti@example.com,30,10\n",
      mapping: { email: "email" },
      dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis", @literasi.id.to_s => "Literasi Sains" }
    }

    rows = CompetencyAchievementCalculator.new(student: users(:siti), period: @period).call
    keterampilan_row = rows.find { |r| r.item == @keterampilan }
    komunikasi_row = rows.find { |r| r.item == @komunikasi }
    assert_equal 75.0, keterampilan_row.percentage
    assert_equal 50.0, komunikasi_row.percentage
    assert_equal 1, keterampilan_row.dimension_count

    sign_in users(:siti)
    get academic_assessments_path
    assert_response :success
    assert_match "Capaian per Ranah Kompetensi", response.body
    assert_match @keterampilan.title, response.body
    assert_match "75.0%", response.body
  end

  test "dimensi tanpa pemetaan tidak menyumbang ke peta kompetensi" do
    @penalaran.update!(competency_item: nil)
    @literasi.update!(competency_item: nil)
    sign_in @admin
    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: "email,Penalaran Klinis\nsiti@example.com,30\n",
      mapping: { email: "email" }, dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis" }
    }

    assert_empty CompetencyAchievementCalculator.new(student: users(:siti), period: @period).call
  end

  test "dimensi yang dipetakan ke sub-kompetensi naik ke ranah induknya" do
    sub = @framework.competency_items.create!(title: "Anamnesis & Pemeriksaan Fisik", parent: @keterampilan)
    @penalaran.update!(competency_item: sub)
    sign_in @admin
    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: "email,Penalaran Klinis\nsiti@example.com,30\n",
      mapping: { email: "email" }, dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis" }
    }

    rows = CompetencyAchievementCalculator.new(student: users(:siti), period: @period).call
    assert_equal [ @keterampilan ], rows.map(&:item)
    assert_equal 75.0, rows.first.percentage
  end

  test "nilai periode lain tidak ikut" do
    other = AcademicPeriod.create!(name: "Periode Lain", start_date: 2.years.ago.to_date, end_date: 1.year.ago.to_date)
    @cbt.update!(academic_period: other)
    sign_in @admin
    post import_create_admin_assessment_event_path(@cbt), params: {
      csv_text: "email,Penalaran Klinis\nsiti@example.com,30\n",
      mapping: { email: "email" }, dimension_mapping: { @penalaran.id.to_s => "Penalaran Klinis" }
    }

    assert_empty CompetencyAchievementCalculator.new(student: users(:siti), period: @period).call
  end

  test "tab dimensi: semua pilihan ranah terhubung ke formulir pemetaan, tanpa formulir bersarang" do
    sign_in @admin
    get admin_assessment_event_path(@cbt, tab: "dimensi")
    assert_response :success
    assert_no_nested_forms(response.body)
    assert_select "form#dimension-map-form[action=?]", bulk_map_admin_assessment_event_assessment_dimensions_path(@cbt)
    [ @penalaran, @literasi ].each do |dimension|
      assert_select "select[name='competency_item_ids[#{dimension.id}]'][form='dimension-map-form']"
    end
    assert_select "input[type=submit][value='Simpan Pemetaan'][form='dimension-map-form']"
  end
end
