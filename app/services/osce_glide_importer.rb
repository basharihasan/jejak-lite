# frozen_string_literal: true

# Impor "Penilaian OSCE" berformat ekspor Glide (data_osce_glide.csv) —
# padanan OsceGlideImporter jejak.pro. Satu baris = satu station yang diuji:
#
#   emailYangDiuji (→ emailMahasiswa2..5)  mahasiswa (akun berperan mahasiswa)
#   emailPenguji                           penguji (bila terdaftar)
#   tanggalUjianX → tanggalEntry → tanggal5  waktu ujian (UTC → WIB)
#   Anamnesis … PerilakuProfesional        8 dimensi klinis, skala 0–3
#   globalRating, halBaik, perluDitingkatkan, refleksi, station, kasus, IDSoal
#   $rowID                                 kunci idempoten (baris yang sama
#                                          tidak pernah diimpor dua kali)
#
# Event tujuan: event OSCE yang dipilih admin, atau — bawaan — satu event per
# HARI ujian ("OSCE 20 Oktober 2025", kode OSCE-GLIDE-2025-10-20), padanan
# rekap Sesi OSCE per hari jejak.pro. Di data Glide nyata kolom PeriodeUjian
# dan tanggalUjianX kosong, jadi tanggal entri yang menentukan sesinya.
#
# Nilai OSCE mahasiswa pada event = rangkuman station-nya (OsceStationSummary).
#
# Dua tahap supaya berkas penuh (±18 ribu baris) selesai dalam satu
# permintaan: (1) validasi tiap baris & siapkan event-nya, (2) buat percobaan,
# sisipkan station, dan rangkum — semuanya massal.
class OsceGlideImporter
  STUDENT_EMAIL_KEYS = %w[emailyangdiuji emailmahasiswa2 emailmahasiswa3 emailmahasiswa4 emailmahasiswa5 emailmahasiswa email].freeze
  DATE_KEYS = %w[tanggalujianx tanggalujian tanggalentry tanggal5 tanggal].freeze
  CODE_PREFIX = "OSCE-GLIDE-"
  # Station disisipkan massal per 1000 baris — berkas tabel Penilaian OSCE
  # penuh berisi belasan ribu baris dan harus selesai dalam satu permintaan.
  BATCH = 1000

  def initialize(csv_text:, glide_import:, user: nil, target_event: nil, study_program: nil, academic_period: nil)
    @csv_text = GlideCsv.read(csv_text)
    @import = glide_import
    @user = user
    @target_event = target_event
    @study_program = study_program
    @academic_period = academic_period
    @events = {}
    @dimension_ready = Set.new
    @row_keys = Set.new
    @touched_event_ids = Set.new
    @candidates = []
    @instance_ids = {}
    @locked = Set.new
  end

  def call
    table = GlideCsv.parse(@csv_text)
    keys = table.headers.compact.map { |header| GlideCsv.normalize_key(header) }
    unless STUDENT_EMAIL_KEYS.any? { |key| keys.include?(key) }
      return abort!("Kolom email mahasiswa (emailYangDiuji) tidak ditemukan — berkas ini bukan ekspor Penilaian OSCE.")
    end
    unless (OsceStationScore::DIMENSIONS.keys + [ "globalrating" ]).any? { |key| keys.include?(key) }
      return abort!("Kolom dimensi OSCE (Anamnesis, PemeriksaanFisik, …) maupun globalRating tidak ditemukan.")
    end
    if @target_event.nil? && @academic_period.nil? && !AcademicPeriod.exists?
      return abort!("Belum ada Tahun/Periode Akademik. Buat dulu sebelum mengimpor.")
    end

    rows = GlideCsv.normalized_rows(table)
    @match_competency = GlideCsv.competency_matcher
    @students = GlideCsv.students_by_email(rows.map { |row| student_email(row) })
    @examiners = User.where(email: rows.map { |row| row["emailpenguji"].to_s.strip.downcase }.compact_blank.uniq)
                     .index_by { |user| user.email.downcase }
    @imported_row_ids = OsceStationScore.where(external_row_id: rows.filter_map { |row| row["rowid"].to_s.strip.presence })
                                        .pluck(:external_row_id).to_set

    # Satu transaksi per unggahan: cepat, dan galat basis data di tengah jalan
    # tidak meninggalkan setengah berkas. Galat validasi per baris tetap
    # dicatat dan barisnya saja yang dilewati.
    ActiveRecord::Base.transaction do
      rows.each.with_index(2) { |row, line| validate(row, line) }
      resolve_instances!
      insert_stations!
      summarize_instances!
    end
    finish!
  rescue CSV::MalformedCSVError => e
    abort!("CSV tidak dapat dibaca: #{e.message}")
  end

  private

  # Tahap 1: baris yang lolos menjadi kandidat station (tanpa percobaan dulu).
  def validate(row, line)
    return if row.values.all?(&:blank?)

    @import.total_rows += 1
    row_id = row["rowid"].to_s.strip.presence
    return @import.add_skip("sudah_diimpor") if row_id && @imported_row_ids.include?(row_id)

    email = student_email(row)
    student = @students[email]
    return @import.add_skip("mahasiswa_tidak_ditemukan") if student.nil?

    scores = {}
    OsceStationScore::DIMENSIONS.each do |key, label|
      value = GlideCsv.number(row[key])
      next if value.nil?
      if value == :invalid || !value.between?(0, OsceStationScore::MAX_DIMENSION_SCORE)
        return @import.add_error("Baris #{line} (#{email}): #{label} \"#{row[key]}\" di luar skala 0–#{OsceStationScore::MAX_DIMENSION_SCORE}.")
      end

      scores[key] = value
    end
    global_rating = row["globalrating"].to_s.strip.presence
    return @import.add_skip("tanpa_nilai") if scores.empty? && global_rating.nil?

    assessed_at = assessed_time(row, line, email)
    return if assessed_at.nil?

    event = @target_event || event_for(assessed_at.to_date)
    ensure_dimensions!(event)
    examiner = @examiners[row["emailpenguji"].to_s.strip.downcase]

    # Skala dimensi sudah diperiksa di atas, jadi validasi model tidak perlu
    # diulang per baris saat disisipkan massal.
    @candidates << {
      pair: [ event.id, student.id ],
      attributes: {
        examiner_id: examiner&.id, glide_import_id: @import.id, external_row_id: row_id,
        station: row["station"].to_s.strip.presence, case_title: row["kasus"].to_s.squish.presence,
        question_code: row["idsoal"].to_s.strip.presence,
        scores: scores, checklist_score: OsceStationScore.checklist_from(scores), global_rating: global_rating,
        feedback_keep: row["halbaik"].to_s.strip.presence, feedback_improve: row["perluditingkatkan"].to_s.strip.presence,
        reflection: row["refleksi"].to_s.strip.presence, details: details(row), assessed_at: assessed_at
      }
    }
    @imported_row_ids << row_id if row_id
  rescue ActiveRecord::RecordInvalid => e
    @import.add_error("Baris #{line} (#{email}): #{e.record.errors.full_messages.to_sentence}")
  end

  def student_email(row)
    STUDENT_EMAIL_KEYS.lazy.map { |key| row[key].to_s.strip.downcase }.find(&:present?).to_s
  end

  # Waktu ujian, atau nil (galat dicatat). Tanpa tanggal, hanya event tujuan
  # pilihan admin yang bisa menampung baris itu.
  def assessed_time(row, line, email)
    raw = DATE_KEYS.lazy.map { |key| row[key] }.find(&:present?)
    parsed = GlideCsv.time(raw)
    if parsed == :invalid
      @import.add_error("Baris #{line} (#{email}): tanggal \"#{raw}\" tidak dikenali.")
      return nil
    end
    if parsed.nil?
      return @target_event.exam_date&.in_time_zone || Time.current if @target_event

      @import.add_error("Baris #{line} (#{email}): tanggal ujian kosong — isi tanggalUjianX/tanggalEntry, atau pilih event tujuan.")
      return nil
    end
    # Data Glide nyata memuat entri bertahun 2116 — salah ketik, bukan ujian.
    unless parsed.year.between?(2000, Date.current.year + 1)
      @import.add_error("Baris #{line} (#{email}): tanggal #{parsed.to_date} tidak wajar.")
      return nil
    end
    parsed
  end

  def event_for(date)
    @events[date] ||= begin
      code = "#{CODE_PREFIX}#{date.iso8601}"
      event = AssessmentEvent.find_by(external_code: code) || begin
        created = AssessmentEvent.create!(
          name: "OSCE #{I18n.l(date, format: :long)}", assessment_type: "osce", external_code: code,
          academic_period: @academic_period || GlideCsv.period_for(date), study_program: @study_program,
          exam_date: date, status: "published", max_score: 100, allow_multiple_attempts: false, created_by: @user,
          description: "Sesi OSCE per hari dari berkas Penilaian OSCE Glide#{" (#{@import.filename})" if @import.filename.present?}."
        )
        @import.created_event_ids << created.id
        created
      end
      @touched_event_ids << event.id
      event
    end
  end

  # Delapan dimensi klinis sebagai AssessmentDimension (maks 3) — sumber radar
  # dan Peta Kompetensi lewat pemetaan dimensinya.
  def ensure_dimensions!(event)
    return if @dimension_ready.include?(event.id)

    @touched_event_ids << event.id
    existing = event.assessment_dimensions.to_a
    OsceStationScore::DIMENSIONS.each do |key, label|
      next if existing.any? { |d| d.code == key }

      same_name = existing.find { |d| d.name.casecmp?(label) }
      if same_name
        same_name.update!(code: key, category: same_name.category || "osce_klinis")
      else
        event.assessment_dimensions.create!(name: label, code: key, category: "osce_klinis",
                                            max_score: OsceStationScore::MAX_DIMENSION_SCORE, weight: 1,
                                            competency_item: @match_competency.call(label))
      end
    end
    @dimension_ready << event.id
  end

  # Tahap 2a: percobaan ke-1 tiap (event, mahasiswa). Yang belum ada dibuat
  # massal. Mahasiswa yang sudah punya nilai OSCE dari sumber lain (input
  # manual / impor generik) dikunci — station Glide tidak boleh menimpanya
  # diam-diam, dan rollback tidak bisa memulihkannya.
  def resolve_instances!
    pairs = @candidates.map { |candidate| candidate[:pair] }.uniq
    return if pairs.empty?

    existing = AssessmentInstance.where(assessment_event_id: pairs.map(&:first).uniq, student_id: pairs.map(&:last).uniq, attempt_number: 1)
                                 .pluck(:id, :assessment_event_id, :student_id, :status)
                                 .index_by { |_, event_id, student_id, _| [ event_id, student_id ] }
    with_stations = OsceStationScore.where(assessment_instance_id: existing.values.map(&:first)).distinct.pluck(:assessment_instance_id).to_set

    missing = []
    pairs.each do |pair|
      id, _, _, status = existing[pair]
      if id.nil?
        missing << pair
      elsif status == "scored" && !with_stations.include?(id)
        @locked << pair
      else
        @instance_ids[pair] = id
        @import.filled_instance_ids << id unless status == "scored"
      end
    end

    max_scores = AssessmentEvent.where(id: missing.map(&:first).uniq).pluck(:id, :max_score).to_h
    missing.each_slice(BATCH) do |slice|
      rows = slice.map do |event_id, student_id|
        { assessment_event_id: event_id, student_id: student_id, attempt_number: 1,
          max_score: max_scores[event_id], source: "import", status: "registered" }
      end
      AssessmentInstance.insert_all(rows, returning: %i[id assessment_event_id student_id]).rows.each do |id, event_id, student_id|
        @instance_ids[[ event_id, student_id ]] = id
        @import.created_instance_ids << id
      end
    end
  end

  # Tahap 2b: sisipkan station per 1000 baris. $rowID yang bentrok (unggahan
  # lain berjalan bersamaan) dilewati oleh ON CONFLICT DO NOTHING, bukan
  # menggagalkan seluruh batch.
  def insert_stations!
    created_ids = @import.created_instance_ids.to_set
    rows = []
    @candidates.each do |candidate|
      next @import.add_skip("nilai_lain_sudah_ada") if @locked.include?(candidate[:pair])

      attributes = candidate[:attributes].merge(assessment_instance_id: @instance_ids.fetch(candidate[:pair]))
      next @import.add_skip("station_sudah_ada") if attributes[:external_row_id].nil? && duplicate_station?(attributes, created_ids)

      rows << attributes
    end

    rows.each_slice(BATCH) do |slice|
      inserted = OsceStationScore.insert_all(slice, unique_by: :index_osce_station_scores_on_external_row_id).rows.size
      @import.created_count += inserted
      (slice.size - inserted).times { @import.add_skip("sudah_diimpor") }
    end
  end

  # Baris tanpa $rowID: station yang sama = mahasiswa + soal/station + penguji
  # + hari yang sama (penjaga lapis kedua jejak.pro). Percobaan yang baru
  # dibuat belum punya station di basis data, jadi cukup dicek di memori.
  def duplicate_station?(attributes, created_ids)
    instance_id = attributes[:assessment_instance_id]
    key = [ instance_id, attributes[:question_code] || attributes[:station], attributes[:examiner_id], attributes[:assessed_at].to_date ]
    return true if @row_keys.include?(key)

    @row_keys << key
    return false if created_ids.include?(instance_id)

    OsceStationScore.where(assessment_instance_id: instance_id, station: attributes[:station], question_code: attributes[:question_code],
                           examiner_id: attributes[:examiner_id], assessed_at: attributes[:assessed_at].all_day).exists?
  end

  def details(row)
    {
      "kompetensi" => row["kompetensi"].to_s.squish,
      "sp" => row["sp"], "institusi" => row["institusi"], "periode_ujian" => row["periodeujian"],
      "diagnosis" => row["diagnosis"],
      "diagnosis_banding" => [ row["diagnosisbanding"], row["diagnosisbanding2"] ].compact_blank.presence,
      "resep" => [ row["resep"], row["resep2"], row["resep3"], row["resep4"], row["resep5"] ].compact_blank.presence,
      "laboratorium" => row["laboratorium"], "radiologi" => row["radiologi"],
      "penunjang_lainnya" => row["penunjanglainnya"], "interpretasi_penunjang" => row["interpretasipenunjang"],
      "nama_penguji" => row["namapenguji"], "email_penguji" => row["emailpenguji"].to_s.strip.downcase,
      "original_id" => row["originalid"]
    }.transform_values { |value| value.is_a?(String) ? value.strip : value }.compact_blank
  end

  # Rangkum station tiap percobaan yang tersentuh. Percobaan yang dibuat
  # unggahan ini tetapi tak satu pun station-nya tersimpan dibuang lagi.
  def summarize_instances!
    ids = @instance_ids.values
    with_stations = OsceStationScore.where(assessment_instance_id: ids).distinct.pluck(:assessment_instance_id)
    empty_created = @import.created_instance_ids.map(&:to_i) & (ids - with_stations)
    AssessmentInstance.where(id: empty_created).delete_all
    @import.created_instance_ids = @import.created_instance_ids - empty_created
    OsceStationSummary.refresh!(ids - empty_created)
  end

  def abort!(message)
    @import.add_error(message)
    finish!
  end

  def finish!
    @import.options = @import.options.merge("event_ids" => @touched_event_ids.to_a)
    @import.save!
    @import
  end
end
