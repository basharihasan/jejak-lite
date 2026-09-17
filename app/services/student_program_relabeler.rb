# frozen_string_literal: true

require "csv"

# Relabel prodi mahasiswa secara massal dari CSV (Konfigurasi → Relabel Prodi
# Mahasiswa) — padanan /management/student_relabel jejak.pro, tanpa mode
# "Tandai Lulus" karena jejak-lite tidak punya status/persona alumni.
#
# Dua aksi, keduanya berujung sama (users.study_program_id diganti):
#   pindah — pindahkan mahasiswa ke prodi tujuan. Untuk kaprodi, controller
#            mengisi restrict_to_study_program_id supaya hanya mahasiswa
#            prodinya sendiri yang bisa dipindahkan.
#   klaim  — labeli mahasiswa dari prodi mana pun (termasuk yang belum
#            berprodi) ke prodi kaprodi yang login. Tujuannya dikunci di
#            controller, bukan di sini.
#
# Kolom CSV (baris pertama = header, urutan bebas, pemisah koma/titik koma):
#   email*   — email akun, atau NPM/NIM lama
#   npm      — NPM/NIM baru di prodi tujuan; kosong = NPM lama dipertahankan
#   angkatan — angkatan di prodi tujuan; kosong = angkatan default form,
#              atau tidak diubah bila default juga kosong
#
# Selalu dua tahap: #matches mencocokkan tanpa menyimpan apa pun; #apply!
# memakai hasil pencocokan yang dihitung ulang dari CSV yang sama (data bisa
# berubah di antara klik Pratinjau dan Terapkan) lalu menyimpan semua baris
# "siap" dalam satu transaksi — gagal satu, tidak ada yang berubah.
class StudentProgramRelabeler
  class Error < StandardError; end

  MODES = %w[pindah klaim].freeze
  MAX_ROWS = 2000
  READY = "siap"

  ALIASES = {
    identifier: %w[email e_mail surel identifier email_npm npm_lama nim_lama],
    npm: %w[npm npm_baru nim nim_baru],
    cohort_year: %w[angkatan angkatan_baru cohort_year tahun_angkatan]
  }.freeze

  Match = Struct.new(:line, :identifier, :user, :from_program, :old_npm, :new_npm,
                     :old_cohort_year, :new_cohort_year, :note, keyword_init: true) do
    def eligible? = note == READY
  end

  Result = Struct.new(:updated, :skipped, keyword_init: true)

  # Isi berkas unggahan bisa ber-BOM (Excel) atau bukan UTF-8 yang sah (ekspor
  # Windows-1252). Kolomnya hanya email/NPM/angkatan, jadi karakter rusak
  # cukup dibuang — yang penting teksnya aman di-round-trip lewat hidden field.
  def self.normalize_csv(raw)
    raw.to_s.dup.force_encoding("UTF-8").scrub("").delete_prefix("﻿")
  end

  def initialize(csv:, mode:, target_study_program:, actor: nil,
                 restrict_to_study_program_id: nil, default_cohort_year: nil)
    raise Error, "Pilih aksi yang valid." unless MODES.include?(mode.to_s)
    raise Error, "Pilih program studi tujuan." if target_study_program.nil?

    @csv = self.class.normalize_csv(csv)
    @mode = mode.to_s
    @target = target_study_program
    @actor = actor
    @restrict_source_id = restrict_to_study_program_id
    @default_cohort_year = nil
    if default_cohort_year.present?
      @default_cohort_year = parse_cohort_year(default_cohort_year) ||
                             raise(Error, "Angkatan default '#{default_cohort_year}' tidak valid — isi tahun 4 digit.")
    end
  end

  def matches
    @matches ||= resolve(parse_rows)
  end

  def apply!
    ready = matches.select(&:eligible?)
    User.transaction do
      ready.each { |m| m.user.update!(pending_attributes(m)) }
    end

    Rails.logger.info(
      "[student_relabel] actor_id=#{@actor&.id} mode=#{@mode} target_study_program_id=#{@target.id} " \
      "updated=#{ready.size} skipped=#{matches.size - ready.size} user_ids=#{ready.map { |m| m.user.id }.join(',')}"
    )
    Result.new(updated: ready.size, skipped: matches.size - ready.size)
  end

  private

  def parse_rows
    return [] if @csv.strip.empty?

    table = CSV.parse(@csv, headers: true, col_sep: separator_for(@csv),
                            header_converters: ->(h) { h.to_s.strip.downcase.gsub(/[\s-]+/, "_") })
    columns = ALIASES.transform_values { |names| table.headers.find { |h| names.include?(h) } }
    unless columns[:identifier]
      raise Error, "Kolom 'email' tidak ditemukan di CSV — unduh template dan cocokkan nama kolomnya."
    end

    rows = []
    table.each.with_index(2) do |row, line|
      identifier = row[columns[:identifier]].to_s.strip
      next if identifier.empty?

      rows << { line: line, identifier: identifier,
                npm: cell(row, columns[:npm]), cohort_year: cell(row, columns[:cohort_year]) }
    end
    raise Error, "CSV berisi #{rows.size} baris — maksimal #{MAX_ROWS} per unggahan, pecah berkasnya." if rows.size > MAX_ROWS

    rows
  rescue CSV::MalformedCSVError => e
    raise Error, "CSV tidak dapat dibaca: #{e.message}"
  end

  def cell(row, column)
    column ? row[column].to_s.strip.presence : nil
  end

  def separator_for(content)
    first = content.lines.first.to_s
    first.count(";") > first.count(",") ? ";" : ","
  end

  def resolve(rows)
    identifiers = rows.map { |r| r[:identifier] }
    emails = identifiers.select { |i| i.include?("@") }.map(&:downcase).uniq
    npms = identifiers.reject { |i| i.include?("@") }.uniq
    users = User.includes(:roles, :study_program)
    by_email = emails.empty? ? {} : users.where("LOWER(email) IN (?)", emails).index_by { |u| u.email.downcase }
    by_npm = npms.empty? ? {} : users.where(identifier_number: npms).group_by(&:identifier_number)

    candidates = rows.map do |row|
      ident = row[:identifier]
      ident.include?("@") ? Array(by_email[ident.downcase]) : Array(by_npm[ident])
    end
    user_counts = candidates.filter_map { |found| found.first.id if found.one? }.tally

    new_npms = rows.filter_map { |r| r[:npm] }
    npm_counts = new_npms.tally
    npm_owner_ids = new_npms.empty? ? {} : User.where(identifier_number: new_npms).pluck(:identifier_number, :id)
                                               .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }

    rows.zip(candidates).map do |row, found|
      user = found.one? ? found.first : nil
      new_npm = row[:npm]
      new_npm = nil if user && new_npm == user.identifier_number
      cohort = row[:cohort_year] ? parse_cohort_year(row[:cohort_year]) : @default_cohort_year
      cohort = nil if user && cohort == user.cohort_year

      match = Match.new(line: row[:line], identifier: row[:identifier], user: user,
                        from_program: user&.study_program, old_npm: user&.identifier_number, new_npm: new_npm,
                        old_cohort_year: user&.cohort_year, new_cohort_year: cohort)
      match.note = note_for(match, row, found,
                            user_count: user ? user_counts[user.id] : 0,
                            npm_count: row[:npm] ? npm_counts[row[:npm]] : 0,
                            npm_owner_ids: row[:npm] ? npm_owner_ids.fetch(row[:npm], []) : [])
      match
    end
  end

  def note_for(match, row, found, user_count:, npm_count:, npm_owner_ids:)
    return "tidak ditemukan" if found.empty?
    return "NPM ini dipakai #{found.size} akun — gunakan email" if found.size > 1

    user = match.user
    return "bukan akun mahasiswa — dilewati" unless user.roles.any? { |r| r.code == "mahasiswa" }
    return "akun yang sama muncul #{user_count}× di CSV — dilewati" if user_count > 1
    if row[:cohort_year] && parse_cohort_year(row[:cohort_year]).nil?
      return "angkatan '#{row[:cohort_year]}' tidak terbaca (isi tahun 4 digit) — dilewati"
    end
    return "di luar prodi Anda — dilewati" if @restrict_source_id && user.study_program_id != @restrict_source_id

    if match.new_npm
      return "NPM baru dobel di CSV ini — dilewati" if npm_count > 1
      return "NPM baru sudah dipakai akun lain — dilewati" if npm_owner_ids.any? { |id| id != user.id }
    end
    return "sudah sesuai — tidak ada perubahan" unless changes?(match)

    errors = validation_errors(match)
    return "data akun tidak valid (#{errors}) — perbaiki di Pengguna dulu" if errors

    READY
  end

  def changes?(match)
    match.user.study_program_id != @target.id || match.new_npm.present? || match.new_cohort_year.present?
  end

  # Cek validasi model di tahap pratinjau, supaya satu akun lama yang datanya
  # tidak lolos validasi (mis. nomor telepon berformat aneh hasil impor) sudah
  # ketahuan sebelum Terapkan — bukan menggagalkan transaksi seluruh batch.
  def validation_errors(match)
    user = match.user
    user.assign_attributes(pending_attributes(match))
    user.valid? ? nil : user.errors.full_messages.to_sentence
  ensure
    user&.restore_attributes
  end

  def pending_attributes(match)
    attrs = { study_program_id: @target.id }
    attrs[:identifier_number] = match.new_npm if match.new_npm
    attrs[:cohort_year] = match.new_cohort_year if match.new_cohort_year
    attrs
  end

  # Hanya tahun 4 digit (Excel kadang menulis "2026.0"), dalam rentang yang
  # sama dengan validasi User#cohort_year.
  def parse_cohort_year(value)
    digits = value.to_s.strip[/\A(\d{4})(?:\.0+)?\z/, 1]
    return nil unless digits

    year = digits.to_i
    year > 1950 && year <= Date.current.year + 1 ? year : nil
  end
end
