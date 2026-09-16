# frozen_string_literal: true

# Satu label menu/istilah yang diganti admin. Lihat Terminology untuk daftar
# kunci yang sah dan kapan penggantiannya berlaku.
class TerminologyOverride < ApplicationRecord
  MAX_LENGTH = 80

  belongs_to :updated_by, class_name: "User", optional: true

  normalizes :value, with: ->(value) { value.to_s.squish }

  validates :key, presence: true, uniqueness: true
  validates :value, presence: true, length: { maximum: MAX_LENGTH }
  validate :key_is_editable

  def self.to_h
    pluck(:key, :value).to_h
  end

  # Simpan seluruh isian formulir sekaligus: isian kosong atau sama dengan
  # bawaan menghapus penggantian (kembali ke bawaan). Semua-atau-tidak;
  # mengembalikan daftar pesan galat (kosong = berhasil).
  def self.apply!(values, by:)
    editable = Terminology.entries.index_by(&:key)
    existing = all.index_by(&:key)
    errors = []

    transaction do
      values.each do |key, raw|
        entry = editable[key.to_s]
        next errors << "Kunci #{key} tidak dikenal." unless entry

        value = raw.to_s.squish
        record = existing[entry.key]
        if value.blank? || value == entry.default_value
          record&.destroy!
        elsif record.nil? || record.value != value
          record ||= new(key: entry.key)
          record.assign_attributes(value: value, updated_by: by)
          errors.concat(record.errors.full_messages.map { |message| "#{entry.default_value}: #{message}" }) unless record.save
        end
      end
      raise ActiveRecord::Rollback if errors.any?
    end
    errors
  end

  private

  def key_is_editable
    errors.add(:key, "tidak bisa diganti") unless Terminology.keys.include?(key)
  end
end
