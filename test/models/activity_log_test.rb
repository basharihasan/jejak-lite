require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  test "wajib punya title, activity_date, category valid" do
    log = ActivityLog.new(user: users(:budi))
    assert_not log.valid?
    assert_includes log.errors[:title], "tidak boleh kosong"
    assert_includes log.errors[:activity_date], "tidak boleh kosong"
    assert_includes log.errors[:category], "tidak termasuk"
  end

  test "category_label menerjemahkan kode ke label" do
    assert_equal "Klinis", activity_logs(:jaga_igd).category_label
    assert_equal "Non-Klinis", activity_logs(:penyuluhan_stunting).category_label
  end

  test "ensure_patient_code! membuat kode sekali dan memakainya ulang" do
    log = activity_logs(:jaga_igd)
    assert_nil log.patient_code

    code = log.ensure_patient_code!
    assert_match(/\AP-[A-Z0-9]{8}\z/, code)
    assert_equal code, log.ensure_patient_code!
  end

  test "scope klinis/non_klinis menyaring berdasar kategori" do
    assert_includes ActivityLog.klinis, activity_logs(:jaga_igd)
    assert_not_includes ActivityLog.klinis, activity_logs(:penyuluhan_stunting)
  end

  test "bisa ditautkan ke beberapa simpul kompetensi" do
    log = activity_logs(:jaga_igd)
    log.competency_item_ids = [ competency_items(:domain_klinis).id, competency_items(:sub_anamnesis).id ]

    assert_equal 2, log.competency_items.count
    assert_includes ActivityLog.tagged_with(competency_items(:domain_klinis).id), log
    assert_not_includes ActivityLog.tagged_with(competency_items(:domain_komunikasi).id), log
  end

  test "delivery_mode_label menerjemahkan kode ke label" do
    log = activity_logs(:jaga_igd)
    log.delivery_mode = "daring"
    assert_equal "Daring", log.delivery_mode_label
  end

  test "domain menurunkan kategori, waktu mulai menurunkan tanggal" do
    log = ActivityLog.new(user: users(:siti), title: "Poliklinik pagi",
                          academic_activity_subdomain: academic_activity_subdomains(:poliklinik),
                          started_at: Time.zone.local(2026, 9, 12, 23, 30))

    assert log.valid?, log.errors.full_messages.to_sentence
    assert_equal academic_activity_domains(:praktek), log.academic_activity_domain
    assert_equal "klinis", log.category
    assert_equal Date.new(2026, 9, 12), log.activity_date, "tanggal mengikuti zona Asia/Jakarta, bukan UTC"
    assert log.clinical?
  end

  test "semester diisi otomatis hanya bila tepat satu periode mencakup tanggalnya" do
    log = ActivityLog.new(user: users(:siti), title: "Tutorial", academic_activity_domain: academic_activity_domains(:belajar_mengajar),
                          activity_date: Date.current)
    log.valid?
    assert_equal academic_periods(:current_period), log.academic_period

    AcademicPeriod.create!(name: "Periode Tumpang Tindih", start_date: 1.week.ago.to_date, end_date: 1.week.from_now.to_date)
    log = ActivityLog.new(user: users(:siti), title: "Tutorial", academic_activity_domain: academic_activity_domains(:belajar_mengajar),
                          activity_date: Date.current)
    log.valid?
    assert_nil log.academic_period
  end

  test "label kegiatan lama jatuh ke kategori dan teks bebas" do
    legacy = activity_logs(:jaga_igd)
    assert_equal "Klinis", legacy.domain_label
    assert_equal "Rawat Jalan", legacy.kind_label
    assert_equal "Rawat Jalan", legacy.taxonomy_detail

    tutorial = activity_logs(:tutorial_siti)
    assert_equal "Belajar Mengajar", tutorial.domain_label
    assert_equal "Tutorial", tutorial.kind_label
  end

  test "rotasi klinik harus milik pemilik kegiatan dan waktu selesai tidak mendahului mulai" do
    log = activity_logs(:jaga_igd)
    log.clinical_rotation = clinical_rotations(:ongoing_rotation_siti)
    log.started_at = Time.zone.local(2026, 9, 12, 10)
    log.ended_at = Time.zone.local(2026, 9, 12, 9)

    assert_not log.valid?
    assert_includes log.errors[:clinical_rotation], "bukan rotasi milik pemilik kegiatan ini"
    assert_includes log.errors[:ended_at], "harus setelah waktu mulai"
  end

  test "tautan bukti hanya menerima http/https" do
    log = activity_logs(:tutorial_siti)
    log.evidence_url = "javascript:alert(1)"
    assert_not log.valid?
    assert_includes log.errors[:evidence_url], "harus diawali http:// atau https://"
  end

  test "domain yang dipakai kegiatan tidak bisa dihapus, yang belum dipakai bisa beserta isinya" do
    used = academic_activity_domains(:belajar_mengajar)
    assert_not used.destroy
    assert AcademicActivitySubdomain.exists?(academic_activity_subdomains(:tutorial).id)

    unused = academic_activity_domains(:prestasi)
    template_id = academic_activity_templates(:juara_1).id
    assert unused.destroy
    assert_not AcademicActivityTemplate.exists?(template_id)
  end

  test "move! menggeser urutan di antara saudara saja" do
    poliklinik = academic_activity_subdomains(:poliklinik)
    assert poliklinik.move!(:up)
    assert_equal %w[Poliklinik Jaga\ UGD], academic_activity_domains(:praktek).academic_activity_subdomains.reload.map(&:name)
    assert_not academic_activity_subdomains(:poliklinik).reload.move!(:up), "sudah paling atas"
    assert_equal 1, academic_activity_subdomains(:tutorial).reload.position, "domain lain tidak tersentuh"
  end
end
