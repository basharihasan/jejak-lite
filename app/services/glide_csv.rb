# frozen_string_literal: true

require "csv"

# Utilitas bersama importer CSV berformat ekspor Glide (CbtGlideImporter,
# OsceGlideImporter). Header dinormalisasi seperti di jejak.pro — huruf kecil,
# hanya a-z0-9 — sehingga "emailYangDiuji", "Email yang diuji", dan
# "email_yang_diuji" dibaca sama.
module GlideCsv
  NUMBER = /\A-?\d+(\.\d+)?\z/
  # Tiga huruf pertama nama bulan Indonesia/Inggris — dengan singkatannya, dan
  # toleran salah ketik di belakangnya ("Septermber").
  MONTHS = {
    "jan" => 1, "feb" => 2, "peb" => 2, "mar" => 3, "apr" => 4, "mei" => 5, "may" => 5, "jun" => 6,
    "jul" => 7, "agu" => 8, "agt" => 8, "ags" => 8, "aug" => 8, "sep" => 9, "okt" => 10, "oct" => 10,
    "nov" => 11, "nop" => 11, "des" => 12, "dec" => 12
  }.freeze

  module_function

  def normalize_key(header)
    header.to_s.downcase.gsub(/[^a-z0-9]/, "")
  end

  # Teks UTF-8 tanpa BOM. Berkas yang bukan UTF-8 (simpanan Excel Windows)
  # dibaca sebagai Windows-1252 supaya nama beraksen tidak membuat CSV gagal.
  def read(raw)
    text = raw.to_s.dup.force_encoding("UTF-8")
    text = raw.to_s.dup.force_encoding("Windows-1252").encode("UTF-8") unless text.valid_encoding?
    text.delete_prefix("﻿")
  end

  def parse(text)
    CSV.parse(text, headers: true, col_sep: AssessmentScoreImporter.detect_separator(text))
  end

  # Baris CSV → { kunci_normal => nilai }. Header kembar: yang pertama menang.
  # Header dinormalisasi sekali per tabel, bukan per sel.
  def normalized_rows(table)
    keys = table.headers.map { |header| normalize_key(header) }
    table.map do |row|
      row.fields.each_with_index.with_object({}) do |(value, index), acc|
        key = keys[index]
        acc[key] = value if key.present? && !acc.key?(key)
      end
    end
  end

  # nil bila kosong atau "-", :invalid bila bukan angka. Koma desimal diterima.
  def number(raw)
    value = raw.to_s.strip.tr(",", ".")
    return nil if value.empty? || value == "-"
    return :invalid unless value.match?(NUMBER)

    value.to_f
  end

  # Waktu di zona aplikasi (WIB). Diterima ISO-8601 — termasuk "…Z" ekspor
  # Glide, dikonversi dari UTC — "2026-06-06", "06/06/2026" (hari/bulan/
  # tahun, opsional jam), dan "6 Juni 2026" / "Sabtu, 6 Jun 2026 08:00".
  # nil bila kosong, :invalid bila tak terbaca.
  def time(raw)
    value = raw.to_s.strip
    return nil if value.empty?

    case value
    when %r{\A(\d\d?)[/.-](\d\d?)[/.-](\d{4})(?:[ T](\d\d?):(\d\d)(?::(\d\d))?)?\z}
      Time.zone.local($3.to_i, $2.to_i, $1.to_i, $4.to_i, $5.to_i, $6.to_i)
    when /\A(?:[[:alpha:]]+,\s*)?(\d\d?)\s+([[:alpha:]]+)\.?\s+(\d{4})(?:,?\s+(\d\d?)[:.](\d\d))?\z/
      month = MONTHS[$2[0, 3].downcase]
      month ? Time.zone.local($3.to_i, month, $1.to_i, $4.to_i, $5.to_i) : :invalid
    when /\A\d{4}-\d\d?-\d\d?/
      Time.zone.parse(value) || :invalid
    else
      :invalid
    end
  rescue ArgumentError
    :invalid
  end

  # Periode yang memuat tanggal; jatuh ke periode berjalan, lalu periode terbaru.
  def period_for(date)
    AcademicPeriod.where("start_date <= ? AND end_date >= ?", date, date).order(start_date: :desc).first ||
      AcademicPeriod.current.first || AcademicPeriod.ordered.first
  end

  # Hanya akun berperan mahasiswa — padanan StudentProfile jejak.pro — supaya
  # email dosen yang nyasar ke kolom mahasiswa tidak menjadi peserta ujian.
  def students_by_email(emails)
    User.joins(:roles).where(roles: { code: "mahasiswa" }, email: emails.compact_blank.uniq)
        .distinct.index_by { |user| user.email.downcase }
  end

  # Ranah kompetensi yang judulnya SAMA PERSIS (setelah normalisasi) dengan
  # nama dimensi — mis. kolom CBT "Komunikasi efektif" ↔ ranah "Komunikasi
  # Efektif". Judul ganda lintas kerangka tidak dipetakan (ambigu).
  def competency_matcher
    by_title = CompetencyItem.all.group_by { |item| normalize_key(item.title) }
    ->(name) { (matches = by_title[normalize_key(name)]) && matches.size == 1 ? matches.first : nil }
  end
end
