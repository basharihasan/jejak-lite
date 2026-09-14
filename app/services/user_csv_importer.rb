# frozen_string_literal: true

require "csv"

# Impor pengguna massal dari CSV (Konfigurasi → Pengguna → Impor CSV).
#
# Kolom (header baris pertama, urutan bebas, huruf kecil/besar diabaikan):
#   email* | nama* | peran | prodi
#   - peran : kode dipisah "+" atau ";" (mahasiswa, dosen, preseptor, kaprodi, admin);
#             kosong → mahasiswa
#   - prodi : kode StudyProgram (pssk / pspd) atau namanya; kosong → tidak diubah
#
# Akun baru dibuat dengan kata sandi bawaan User::DEFAULT_PASSWORD dan langsung
# terkonfirmasi (admin yang mengimpor bertanggung jawab atas emailnya). Akun
# yang sudah ada hanya diperbarui nama/peran/prodi-nya — kata sandi tidak
# disentuh. Setiap baris dilaporkan, bukan gagal senyap.
class UserCsvImporter
  Result = Struct.new(:created, :updated, :errors, keyword_init: true) do
    def total = created.size + updated.size + errors.size
  end

  ALIASES = {
    "email" => %w[email e-mail surel],
    "nama"  => %w[nama nama_lengkap full_name name],
    "peran" => %w[peran role roles peran_kode],
    "prodi" => %w[prodi program_studi study_program kode_prodi]
  }.freeze

  def initialize(io)
    @io = io
  end

  def call
    result = Result.new(created: [], updated: [], errors: [])
    rows = parse

    rows.each_with_index do |row, idx|
      line = idx + 2
      email = row["email"].to_s.strip.downcase
      name  = row["nama"].to_s.strip
      if email.blank? || name.blank?
        result.errors << "Baris #{line}: email dan nama wajib diisi."
        next
      end

      roles = resolve_roles(row["peran"])
      if roles.nil?
        result.errors << "Baris #{line}: kode peran tidak dikenal (#{row['peran']})."
        next
      end

      study_program = resolve_study_program(row["prodi"])
      if row["prodi"].present? && study_program.nil?
        result.errors << "Baris #{line}: prodi tidak dikenal (#{row['prodi']})."
        next
      end

      user = User.find_or_initialize_by(email: email)
      new_record = user.new_record?
      user.full_name = name
      user.study_program = study_program if study_program
      if new_record
        user.password = user.password_confirmation = User::DEFAULT_PASSWORD
        user.confirmed_at = Time.current
      end

      User.transaction do
        user.save!
        roles.each { |r| user.roles << r unless user.roles.include?(r) }
        user.update_column(:active_role_id, roles.first.id) if user.active_role_id.nil?
      end

      (new_record ? result.created : result.updated) << email
    rescue ActiveRecord::RecordInvalid => e
      result.errors << "Baris #{line}: #{e.record.errors.full_messages.to_sentence}"
    end

    result
  rescue CSV::MalformedCSVError => e
    Result.new(created: [], updated: [], errors: [ "Berkas CSV tidak dapat dibaca: #{e.message}" ])
  end

  private

  def parse
    content = @io.read
    content = content.force_encoding("UTF-8").delete_prefix("﻿")
    table = CSV.parse(content, headers: true, col_sep: detect_separator(content))
    table.map { |r| normalize(r.to_h) }
  end

  def detect_separator(content)
    first = content.lines.first.to_s
    first.count(";") > first.count(",") ? ";" : ","
  end

  def normalize(hash)
    out = {}
    hash.each do |k, v|
      key = k.to_s.strip.downcase.tr(" ", "_")
      canonical = ALIASES.find { |_, names| names.include?(key) }&.first
      out[canonical] = v if canonical
    end
    out
  end

  def resolve_roles(value)
    codes = value.to_s.split(/[+;|,]/).map { |c| c.strip.downcase }.reject(&:blank?)
    codes = [ "mahasiswa" ] if codes.empty?
    roles = Role.where(code: codes).to_a
    return nil if roles.size != codes.uniq.size

    codes.map { |c| roles.find { |r| r.code == c } }
  end

  def resolve_study_program(value)
    v = value.to_s.strip
    return nil if v.blank?

    StudyProgram.find_by(code: v.downcase) || StudyProgram.find_by("LOWER(name) = ?", v.downcase)
  end
end
