# frozen_string_literal: true

# Impor "CBT Exam Results" berformat ekspor Glide (data_cbt_exams_glide.csv) —
# padanan CbtGlideImporter jejak.pro, dipetakan ke model jejak-lite:
#
#   exam_code   → AssessmentEvent (external_code); dibuat bila belum ada
#   exam_title  → nama event
#   exam_type   → formative/summative (Formatif/Sumatif) atau progress_test
#                 (tipe event Progress Test)
#   held_at     → tanggal ujian; periode akademik = periode yang memuatnya
#   total_score → nilai percobaan, skala 100
#   kolom lain  → dimensi (mata uji / tinjauan) skala 100, dikelompokkan ke
#                 kategori tinjauan (Area Kompetensi, Sistem Organ, …)
#
# Idempoten seperti jejak.pro: mahasiswa yang sudah bernilai pada ujian yang
# sama dilewati ("sudah diimpor"), jadi mengunggah ulang berkas yang sama
# aman. Untuk mengoreksi nilai: rollback unggahan lama, lalu unggah ulang.
class CbtGlideImporter
  class RowError < StandardError; end

  METADATA_KEYS = %w[
    email examcode examtitle examtype totalscore finalscore nilai nilaiakhir
    rowid heldat no nama npm nim name studentid angkatan kelas prodi
    tanggal tanggalujian date examdate
  ].to_set.freeze
  TOTAL_KEYS = %w[totalscore finalscore nilai nilaiakhir].freeze
  DATE_KEYS = %w[heldat tanggalujian tanggal examdate date].freeze
  MONTHS = %w[januari februari maret april mei juni juli agustus september oktober november desember].freeze

  # Kolom dimensi (dinormalisasi) → kategori tinjauan — DIMENSION_CATEGORY_MAP
  # CbtExam jejak.pro. Kolom yang tidak dikenal masuk "lainnya".
  CATEGORY_KEYS = {
    "kompetensi" => %w[
      profesionalismeetikdanpengembanganpribadi komunikasiefektif penelusurankritisidanmanajemeninformasi
      ketrampilandasarklinis promosikesehatandanpencegahanpenyakit
      aplikasibiomedisperilakuklinisepidemiologipadakedokterankeluarga
      mawasdiridanpengembangandiri profesionalitasyangluhur kolaborasidankerjasama
      keselamatandanmutulayanankesehatan literasisainsataulandasanilmiah
      literasiteknologiinformasidandigitaldankomunikasi keterampilanklinis pengelolaanmasalahkesehatandansumberdaya
    ],
    "sistem_organ" => %w[
      reproduksi kepaladanleher sarafdanperilaku ginjaldansalurankemih endokrindanmetabolisme
      darahdansistemkekebalantubuh kulitotottulangdanjaringanlunak saluranpernafasan
      jantungpembuluhdarahdansistemlimfatik salurancernahepatobilierdanpankreas
      pertumbuhanperkembangandandegenerasi rehabilitasi
      cardiovascularsystem dermatomuscularsystem endocrinemetabolismsystem familymedicine gastrointestinalsystem
      tropicalmedicine genitourinarysystem neurobehaviorspecialsensessystem reproductivesystem
      hematoimmunologysystem respiratorysystem peopleplanetandprosperity
      sistemsaraf psikiatri sistemindra sistemrespirasi sistemkardiovaskular
      sistemgastrointestinalhepatobilierdanpankreas sistemginjaldansalurankemih sistemreproduksi
      sistemendokrinmetabolismedannutrisi sistemhematologidanimunologi sistemmuskuloskeletal sistemintegumen
    ],
    "sistem_kesehatan" => %w[individu keluarga masyarakat manajemenmasalahkesehatanprimer komunitas],
    "siklus_kehidupan" => %w[geriatric adult babyandchild babychild adolescent pregnancyandbirth pregnancybirth],
    "proses_klinis" => %w[
      penapisandiagnosis manajementerapi efeksamping recall konatif kognitif reasoning
      diagnosticapproach medicolegalprofessionalism epidemiologybiostatisticsreseachmethodology
      epidemiologybiostatisticsresearchmethodology managementandtherapy clinicalreasoningskills
      mechanismofdiseases healthpromotionandprevention rehabilitation ebcr
    ],
    "patomekanisme" => %w[
      penyakitneoplasma penyakitinfeksidanimunologi kelainangenetikdancongenital penyakitakibattraumaataukecelakaan
      metabolism metabolic degenerative inflammation congenital infection trauma neoplasm other
    ],
    "setting_klinis" => %w[hospital communitysetting primaryhealthcentre emergency notapplicable nonapplicable],
    "aspek" => %w[proceduralknowledge knowledge attitude healthsystem]
  }.freeze
  DIMENSION_CATEGORIES = CATEGORY_KEYS.flat_map { |category, keys| keys.map { |key| [ key, category ] } }.to_h.freeze

  # exam_title / exam_date dari formulir unggah menimpa isi berkas untuk semua
  # baris (padanan opsi khusus CBT jejak.pro).
  def initialize(csv_text:, glide_import:, user: nil, exam_title: nil, exam_date: nil, study_program: nil, academic_period: nil)
    @csv_text = GlideCsv.read(csv_text)
    @import = glide_import
    @user = user
    @exam_title = exam_title.to_s.strip.presence
    @exam_date = exam_date.presence && Time.zone.local(exam_date.year, exam_date.month, exam_date.day)
    @study_program = study_program
    @academic_period = academic_period
    @events = {}
    @dimensions = {}
    @touched_event_ids = Set.new
  end

  def call
    table = GlideCsv.parse(@csv_text)
    headers = table.headers.compact.map(&:to_s)
    keys = headers.index_with { |header| GlideCsv.normalize_key(header) }
    return abort!("Kolom email tidak ditemukan — berkas ini bukan ekspor CBT Exam Results.") unless keys.value?("email")
    return abort!("Belum ada Tahun/Periode Akademik. Buat dulu sebelum mengimpor.") if @academic_period.nil? && !AcademicPeriod.exists?

    @dimension_headers = headers.reject { |header| keys[header].blank? || METADATA_KEYS.include?(keys[header]) }
    @match_competency = GlideCsv.competency_matcher
    rows = GlideCsv.normalized_rows(table).zip(table.each.to_a)
    @students = GlideCsv.students_by_email(rows.map { |normalized, _| normalized["email"].to_s.strip.downcase })

    # Satu transaksi per unggahan: cepat, dan galat basis data di tengah jalan
    # tidak meninggalkan setengah berkas. Galat validasi per baris tetap
    # dicatat dan barisnya saja yang dilewati (savepoint per baris).
    ActiveRecord::Base.transaction do
      rows.each.with_index(2) { |(normalized, row), line| process(normalized, row, line) }
    end
    finish!
  rescue CSV::MalformedCSVError => e
    abort!("CSV tidak dapat dibaca: #{e.message}")
  end

  private

  def process(data, row, line)
    return if data.values.all?(&:blank?)

    @import.total_rows += 1
    email = data["email"].to_s.strip.downcase
    student = @students[email]
    return @import.add_skip("mahasiswa_tidak_ditemukan") if student.nil?

    total = GlideCsv.number(TOTAL_KEYS.lazy.map { |key| data[key] }.find(&:present?))
    return @import.add_error("Baris #{line} (#{email}): nilai total bukan angka.") if total == :invalid
    return @import.add_skip("nilai_total_kosong") if total.nil?

    title = @exam_title || data["examtitle"].to_s.strip.presence
    held_at = exam_time(data, title, line)
    return if held_at == :invalid

    code = data["examcode"].to_s.strip.presence || inferred_code(title, held_at)
    event = event_for(code, title || code, held_at, data["examtype"])

    instance = AssessmentInstance.find_or_initialize_by(assessment_event: event, student: student, attempt_number: 1)
    return @import.add_skip("sudah_diimpor") if instance.persisted? && instance.status == "scored"

    filled = instance.persisted?
    AssessmentInstance.transaction(requires_new: true) do
      instance.update!(score: total, max_score: event.max_score, status: "scored", source: "import",
                       scored_at: held_at || Time.current)
      write_dimensions!(event, instance, row)
    end
    if filled
      @import.updated_count += 1
      @import.filled_instance_ids << instance.id
    else
      @import.created_count += 1
      @import.created_instance_ids << instance.id
    end
  rescue ActiveRecord::RecordInvalid => e
    @import.add_error("Baris #{line} (#{email}): #{e.record.errors.full_messages.to_sentence}")
  rescue RowError => e
    @import.add_error("Baris #{line} (#{email}): #{e.message}")
  end

  def write_dimensions!(event, instance, row)
    @dimension_headers.each do |header|
      value = GlideCsv.number(row[header])
      next if value.nil?
      raise RowError, "nilai \"#{row[header]}\" pada kolom #{header.squish} bukan angka" if value == :invalid

      dimension = dimension_for(event, header)
      record = instance.assessment_dimension_scores.find_or_initialize_by(assessment_dimension: dimension)
      record.score = value
      record.save!
    end
  end

  def event_for(code, title, held_at, exam_type)
    @events[code] ||= begin
      event = AssessmentEvent.find_by(external_code: code)
      if event
        event.update!(exam_date: held_at.to_date) if event.exam_date.nil? && held_at
      else
        type, purpose = classify(exam_type)
        event = AssessmentEvent.create!(
          name: title, assessment_type: type, exam_purpose: purpose, external_code: code,
          academic_period: @academic_period || GlideCsv.period_for((held_at || Time.current).to_date),
          study_program: @study_program, exam_date: held_at&.to_date, status: "published", max_score: 100,
          allow_multiple_attempts: false, created_by: @user,
          description: "Diimpor dari berkas CBT Exam Results Glide#{" (#{@import.filename})" if @import.filename.present?}."
        )
        @import.created_event_ids << event.id
      end
      @touched_event_ids << event.id
      event
    end
  end

  def dimension_for(event, header)
    cache = @dimensions[event.id] ||= event.assessment_dimensions.to_a
    key = GlideCsv.normalize_key(header)
    name = header.squish
    cache.find { |d| d.code == key || d.name.casecmp?(name) } || begin
      dimension = event.assessment_dimensions.create!(
        name: name, code: key, category: DIMENSION_CATEGORIES.fetch(key, "lainnya"),
        max_score: 100, weight: 1, competency_item: @match_competency.call(name)
      )
      cache << dimension
      dimension
    end
  end

  # [tipe event, tujuan ujian]
  def classify(exam_type)
    case GlideCsv.normalize_key(exam_type)
    when "progresstest" then [ "progress_test", nil ]
    when "formative", "formatif" then [ "cbt", "formative" ]
    when "summative", "sumatif", "" then [ "cbt", "summative" ]
    else [ "cbt", nil ]
    end
  end

  def exam_time(data, title, line)
    return @exam_date if @exam_date

    raw = DATE_KEYS.lazy.map { |key| data[key] }.find(&:present?)
    parsed = GlideCsv.time(raw)
    if parsed == :invalid
      @import.add_error("Baris #{line}: tanggal ujian \"#{raw}\" tidak dikenali — pakai 2026-06-06 atau 06/06/2026.")
      return :invalid
    end
    parsed || time_from_title(title)
  end

  # Judul jejak.pro sering memuat tanggal: "... (060626)" = 6 Juni 2026, atau
  # "... Juni 2026" = 1 Juni 2026.
  def time_from_title(title)
    return nil if title.blank?

    if (match = title.match(/\((\d\d)(\d\d)(\d\d)\)/))
      return Time.zone.local(2000 + match[3].to_i, match[2].to_i, match[1].to_i)
    end
    MONTHS.each_with_index do |month, index|
      if (match = title.downcase.match(/#{month}\s+(\d{4})/))
        return Time.zone.local(match[1].to_i, index + 1, 1)
      end
    end
    nil
  rescue ArgumentError
    nil
  end

  # Berkas tanpa kolom exam_code: kode dari judul (atau nama berkas) + tanggal,
  # supaya dua ujian berbeda dengan nama berkas generik tidak tergabung.
  def inferred_code(title, held_at)
    base = title.presence || File.basename(@import.filename.to_s, ".*").sub(/\A[a-f0-9]{6,32}[._-]/i, "")
    slug = base.to_s.gsub(/[^a-zA-Z0-9]+/, "-").upcase.delete_prefix("-").delete_suffix("-")
    [ "CBT", slug.presence || "EXAM", held_at&.strftime("%Y%m%d") ].compact.join("-")
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
