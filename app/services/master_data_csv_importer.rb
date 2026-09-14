# frozen_string_literal: true

require "csv"

# Impor CSV master data (DiagnosisDefinition / SkillDefinition). Header = nama
# kolom model (name, icd10_code, skdi_level, system_group / category); alias
# Indonesia diterima (nama, kode_icd10, level_skdi, sistem, kategori).
class MasterDataCsvImporter
  ALIASES = {
    "name" => %w[name nama diagnosis keterampilan],
    "icd10_code" => %w[icd10_code icd10 kode_icd10 kode],
    "skdi_level" => %w[skdi_level skdi level_skdi level],
    "system_group" => %w[system_group sistem system],
    "category" => %w[category kategori]
  }.freeze

  def initialize(model, io)
    @model = model
    @io = io
  end

  def call
    result = { created: 0, updated: 0, errors: [] }
    content = @io.read.force_encoding("UTF-8").delete_prefix("﻿")
    first = content.lines.first.to_s
    sep = first.count(";") > first.count(",") ? ";" : ","
    CSV.parse(content, headers: true, col_sep: sep).each_with_index do |row, idx|
      attrs = normalize(row.to_h).slice(*@model.column_names)
      name = attrs["name"].to_s.strip
      if name.blank?
        result[:errors] << "Baris #{idx + 2}: nama kosong"
        next
      end

      record = @model.find_by("LOWER(name) = ?", name.downcase) || @model.new
      new_record = record.new_record?
      record.assign_attributes(attrs.merge("name" => name, "active" => true))
      if record.save
        result[new_record ? :created : :updated] += 1
      else
        result[:errors] << "Baris #{idx + 2}: #{record.errors.full_messages.to_sentence}"
      end
    end
    result
  rescue CSV::MalformedCSVError => e
    { created: 0, updated: 0, errors: [ "CSV tidak dapat dibaca: #{e.message}" ] }
  end

  private

  def normalize(hash)
    out = {}
    hash.each do |k, v|
      key = k.to_s.strip.downcase.tr(" ", "_")
      canonical = ALIASES.find { |_, names| names.include?(key) }&.first
      out[canonical] = v.to_s.strip.presence if canonical
    end
    out
  end
end
