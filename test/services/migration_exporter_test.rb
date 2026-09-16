require "test_helper"
require "tmpdir"

# Paket migrasi ke jejak.pro: isinya lengkap, rahasia tidak ikut, dan kolom
# jejak_pro/*.csv tetap sesuai kontrak JejakLiteBundleImporter di jejak.pro.
class MigrationExporterTest < ActiveSupport::TestCase
  setup do
    @dir = Pathname.new(Dir.mktmpdir("migrasi-jejak-pro"))
  end

  teardown do
    FileUtils.rm_rf(@dir)
  end

  test "paket berisi manifest, salinan lengkap, dan berkas untuk jejak.pro" do
    MigrationExporter.new(dir: @dir).call

    manifest = JSON.parse(@dir.join("manifest.json").read)
    assert_equal "1.1", manifest["format_version"]
    assert_equal "jejak-lite", manifest["source"]["app"]
    assert_equal false, manifest["patient_identity_included"]
    assert_equal User.count, manifest["counts"]["users"]
    assert_equal ClinicalCase.count, manifest["counts"]["jejak_pro/kasus_klinis.csv"]

    %w[pengguna padanan_email periode rotasi_klinik kasus_klinis logbook_kegiatan kompetensi daftar_event_asesmen lampiran].each do |name|
      assert @dir.join("jejak_pro", "#{name}.csv").exist?, "#{name}.csv tidak ada"
      assert_equal Digest::SHA256.file(@dir.join("jejak_pro", "#{name}.csv")).hexdigest,
                   manifest["checksums"]["jejak_pro/#{name}.csv"]
    end
    assert @dir.join("PANDUAN_MIGRASI.md").read.include?("jejak_lite:import")
  end

  test "kata sandi dan token tidak pernah ikut" do
    MigrationExporter.new(dir: @dir).call

    user_rows = JSON.parse(@dir.join("data/users.json").read)
    assert_equal User.count, user_rows.size
    MigrationExporter::SECRET_COLUMNS.each do |column|
      assert user_rows.none? { |row| row.key?(column) }, "#{column} ikut terekspor"
    end
  end

  test "kolom pengguna & rotasi mengikuti importer jejak.pro" do
    MigrationExporter.new(dir: @dir).call

    pengguna = CSV.read(@dir.join("jejak_pro/pengguna.csv"), headers: true)
    assert_equal MigrationExporter::USER_HEADERS, pengguna.headers
    assert_equal "Mahasiswa", pengguna.find { |row| row["email"] == users(:siti).email }["Status"]

    rotasi = CSV.read(@dir.join("jejak_pro/rotasi_klinik.csv"), headers: true)
    assert_equal [ "NPM", "Email Mahasiswa", "Blok Klinis", "Wahana", "Periode", "Mulai", "Selesai", "Status", "Tier", "Email Preseptor" ],
                 rotasi.headers
  end

  test "logbook kegiatan membawa nama domain, subdomain, dan waktu untuk dicocokkan jejak.pro" do
    MigrationExporter.new(dir: @dir).call

    logbook = CSV.read(@dir.join("jejak_pro/logbook_kegiatan.csv"), headers: true)
    assert_equal MigrationExporter::ACTIVITY_HEADERS, logbook.headers
    assert_equal %w[id_jejak_lite email_mahasiswa tanggal judul kategori mode deskripsi refleksi lokasi jumlah_peserta],
                 logbook.headers.first(10), "kolom versi 1.0 tidak boleh bergeser"
    tutorial = logbook.find { |row| row["id_jejak_lite"] == activity_logs(:tutorial_siti).id.to_s }
    assert_equal [ "Belajar Mengajar", "Tutorial", nil ], tutorial.fields("domain", "subdomain", "bentuk_kegiatan")
    assert_equal activity_logs(:tutorial_siti).started_at.iso8601, tutorial["waktu_mulai"]
    assert_equal "https://drive.example.com/bukti-tutorial", tutorial["link_bukti"]

    assert JSON.parse(@dir.join("data/academic_activity_domains.json").read).any? { |row| row["name"] == "Praktek" }
    assert @dir.join("data/terminology_overrides.json").exist?
  end

  test "identitas pasien tidak ikut kecuali diminta" do
    kasus = clinical_cases(:submitted_case_siti)
    kasus.update!(patient_name: "Ny. Rahasia Sekali")

    MigrationExporter.new(dir: @dir.join("tanpa")).call
    assert_no_match "Rahasia", @dir.join("tanpa/jejak_pro/kasus_klinis.csv").read
    assert_no_match "Rahasia", @dir.join("tanpa/data/clinical_cases.json").read
    assert_nil JSON.parse(@dir.join("tanpa/data/clinical_cases.json").read).find { |r| r["id"] == kasus.id }["patient_name"]

    MigrationExporter.new(dir: @dir.join("dengan"), include_patient_identity: true).call
    rows = CSV.read(@dir.join("dengan/jejak_pro/kasus_klinis.csv"), headers: true)
    assert_equal "Ny. Rahasia Sekali", rows.find { |r| r["id_jejak_lite"] == kasus.id.to_s }["nama_pasien"]
    assert JSON.parse(@dir.join("dengan/manifest.json").read)["patient_identity_included"]
  end

  test "nilai membawa persen per ranah kompetensi dari dimensi ujian" do
    event = assessment_events(:cbt_blok)
    event.update!(allow_multiple_attempts: false)
    klinis = competency_items(:domain_klinis)
    dimension = event.assessment_dimensions.create!(name: "Penalaran Klinis", code: "PK", max_score: 40, weight: 1,
                                                    competency_item: klinis)
    instance = event.assessment_instances.find_or_initialize_by(student: users(:siti), attempt_number: 1)
    instance.update!(max_score: 100, score: 70, status: "scored")
    instance.assessment_dimension_scores.create!(assessment_dimension: dimension, score: 30)

    MigrationExporter.new(dir: @dir).call

    index = CSV.read(@dir.join("jejak_pro/daftar_event_asesmen.csv"), headers: true)
    event_row = index.find { |row| row["ID jejak-lite"] == event.id.to_s }
    nilai = CSV.read(@dir.join(event_row["Berkas Nilai"]), headers: true)
    siti = nilai.find { |row| row["email"] == users(:siti).email }

    assert_equal "70.0", siti["nilai_persen"]
    assert_equal "30.0", siti["dimensi:PK — Penalaran Klinis"]
    # 30 dari 40 = 75% pada ranah Keterampilan Klinis
    assert_equal "75.0", siti["kompetensi:#{klinis.id}"]

    kompetensi = CSV.read(@dir.join("jejak_pro/kompetensi.csv"), headers: true)
    assert kompetensi.any? { |row| row["ID jejak-lite"] == klinis.id.to_s && row["Nama"] == klinis.title }
  end
end
