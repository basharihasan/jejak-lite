# frozen_string_literal: true

# Dipakai DopsEvaluation & MiniCexEvaluation — keduanya menilai lewat rubrik
# dimensi tetap (bukan Form Builder dinamis Fase 9, sengaja: rubrik DOPS/
# Mini-CEX baku secara internasional, bukan sesuatu yang perlu dikonfigurasi
# ulang per institusi). Skor 1-9 meniru skala Mini-CEX standar (1-3 di bawah
# harapan, 4-6 sesuai harapan, 7-9 melebihi harapan). Dimensi profesionalisme
# & komunikasi WAJIB diisi (tidak boleh N/A) — meniru aturan yang baru
# diterapkan JEJAK pada DOPS/Mini-CEX asli.
module DimensionScorable
  extend ActiveSupport::Concern

  SCORE_RANGE = (1..9).freeze

  included do
    validates :evaluated_at, presence: true
    validate :required_dimensions_scored
    validate :scores_in_range
  end

  def score_for(key)
    scores&.dig(key.to_s)
  end

  def average_score
    values = scores.to_h.values.compact.map(&:to_i)
    return nil if values.empty?

    (values.sum.to_f / values.size).round(1)
  end

  private

  def required_dimensions_scored
    self.class::REQUIRED_DIMENSIONS.each do |dim|
      next if scores.present? && scores[dim].present?

      errors.add(:scores, "#{self.class::DIMENSIONS[dim]} wajib diisi (tidak boleh N/A)")
    end
  end

  def scores_in_range
    return if scores.blank?

    scores.each do |key, value|
      next if value.blank?
      next if SCORE_RANGE.cover?(value.to_i)

      label = self.class::DIMENSIONS[key] || key
      errors.add(:scores, "#{label} harus antara #{SCORE_RANGE.min}-#{SCORE_RANGE.max}")
    end
  end
end
