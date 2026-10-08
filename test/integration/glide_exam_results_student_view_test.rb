require "test_helper"

# Hasil impor CSV CBT & OSCE (format Glide) sampai ke mahasiswa: rincian
# station OSCE dengan umpan balik penguji, dan radar CBT per kategori tinjauan.
class GlideExamResultsStudentViewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @siti = users(:siti)
    @date = 2.days.ago.to_date
  end

  def run_import(key, csv)
    record = GlideImport.create!(importer_key: key, filename: "berkas.csv")
    importer = key == "cbt" ? CbtGlideImporter : OsceGlideImporter
    importer.new(csv_text: csv, glide_import: record).call
  end

  test "mahasiswa melihat rincian station OSCE beserta umpan balik penguji" do
    run_import("osce", "rowID,emailYangDiuji,emailPenguji,namaPenguji,tanggalEntry,station,kasus,Anamnesis,PerilakuProfesional,globalRating,halBaik,perluDitingkatkan\n" \
                       "s1,siti@example.com,,dr. Penguji Tamu,#{@date.iso8601}T03:00:00Z,4,Asma bronkial,1,3,Borderline,Sopan,Anamnesis belum runtut\n")
    instance = @siti.assessment_instances.joins(:assessment_event).find_by!(assessment_events: { assessment_type: "osce" })

    sign_in @siti
    get student_assessment_path(instance)
    assert_response :success
    assert_select "[data-testid=osce-stations]" do
      assert_select "*", text: /Station 4 — Asma bronkial/
    end
    assert_match "Borderline", response.body
    assert_match "Anamnesis belum runtut", response.body
    assert_match "penguji dr. Penguji Tamu", response.body
    assert_match "Dimensi Klinis OSCE", response.body, "radar memakai kategori dimensi klinis"

    get exam_scores_path
    assert_match instance.assessment_event.name, response.body
  end

  test "radar CBT dikelompokkan per kategori tinjauan" do
    run_import("cbt", "email,exam_code,exam_title,total_score,held_at,Komunikasi efektif,Saraf dan Perilaku,Reasoning\n" \
                      "siti@example.com,CBT-RADAR,CBT Radar,70,#{@date.iso8601},80,60,75\n")
    instance = @siti.assessment_instances.joins(:assessment_event).find_by!(assessment_events: { external_code: "CBT-RADAR" })

    sign_in @siti
    get student_assessment_path(instance)
    assert_select "[data-testid=dimension-profile]"
    %w[Area\ Kompetensi Sistem\ Organ Proses\ Klinis].each { |label| assert_match label, response.body }
    assert_select "[data-testid=osce-stations]", 0
  end
end
