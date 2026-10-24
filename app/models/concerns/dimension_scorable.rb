# frozen_string_literal: true

# Dipakai DopsEvaluation & MiniCexEvaluation — keduanya menilai lewat rubrik
# dimensi tetap (bukan Form Builder dinamis Fase 9, sengaja: rubrik DOPS/
# Mini-CEX baku secara internasional, bukan sesuatu yang perlu dikonfigurasi
# ulang per institusi). Skor 1-9 meniru skala Mini-CEX standar (1-3 di bawah
# harapan, 4-6 sesuai harapan, 7-9 melebihi harapan). Dimensi wajib (lihat
# REQUIRED_DIMENSIONS per model) tidak boleh N/A — meniru aturan JEJAK asli.
#
# Status draft/submitted meniru JEJAK: evaluator bisa mulai menilai lalu
# menyelesaikannya nanti. Notifikasi ke mahasiswa BARU terkirim saat status
# jadi "submitted" (lewat #submit! atau langsung dibuat submitted, default
# kolom) — bukan saat draft dibuat, supaya mahasiswa tidak dapat notifikasi
# untuk evaluasi yang belum selesai ditulis evaluatornya.
module DimensionScorable
  extend ActiveSupport::Concern

  SCORE_RANGE = (1..9).freeze
  # requested = diinisiasi mahasiswa dari kasus, menunggu penilai mengisi
  # rubrik; belum ada skor sehingga aturan dimensi wajib belum berlaku.
  STATUSES = %w[requested draft submitted].freeze
  STATUS_LABELS = { "requested" => "Diminta", "draft" => "Draf", "submitted" => "Terkirim" }.freeze
  VIDEO_URL_FORMAT = %r{\Ahttps?://}i

  included do
    validates :evaluated_at, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :video_recording_url, format: { with: VIDEO_URL_FORMAT }, allow_blank: true
    validate :required_dimensions_scored, unless: :requested?
    validate :scores_in_range
    validate :rotation_belongs_to_student
    validate :evaluator_is_not_student, if: -> { will_save_change_to_evaluator_id? || will_save_change_to_student_id? }

    scope :draft, -> { where(status: "draft") }
    scope :requested, -> { where(status: "requested") }
    # Pekerjaan penilai yang belum selesai: permintaan mahasiswa + draf.
    scope :pending_for_evaluator, -> { where(status: %w[requested draft]) }

    belongs_to :clinical_case, optional: true
    scope :submitted, -> { where(status: "submitted") }

    after_create_commit :notify_student, if: :submitted?
  end

  def score_for(key)
    scores&.dig(key.to_s)
  end

  def average_score
    values = scores.to_h.values.compact.map(&:to_i)
    return nil if values.empty?

    (values.sum.to_f / values.size).round(1)
  end

  def draft?
    status == "draft"
  end

  def requested?
    status == "requested"
  end

  def status_label
    STATUS_LABELS.fetch(status, status)
  end

  def submitted?
    status == "submitted"
  end

  def submit!
    return if submitted?

    update!(status: "submitted")
    notify_student
  end

  # Rata-rata tiap dimensi lintas beberapa evaluasi (mis. semua DOPS milik
  # satu mahasiswa) — dipakai Dashboard Analitik & Capaian Belajar untuk
  # radar chart kompetensi, bukan cuma rata-rata tunggal per evaluasi.
  module ClassMethods
    def avg_dimension_scores(relation = all)
      self::DIMENSIONS.keys.index_with do |key|
        values = relation.filter_map { |evaluation| evaluation.score_for(key) }.map(&:to_i)
        values.any? ? (values.sum.to_f / values.size).round(1) : nil
      end
    end
  end

  private

  def required_dimensions_scored
    self.class::REQUIRED_DIMENSIONS.each do |dim|
      next if scores.present? && scores[dim].present?

      errors.add(:scores, "#{self.class::DIMENSIONS[dim]} wajib diisi (tidak boleh N/A)")
    end
  end

  # Pilihan rotasi di form memuat rotasi semua mahasiswa; rotasi milik
  # mahasiswa lain membuat nilai salah atribusi (dan hilang dari Analitik,
  # yang menghitung per rotasi mahasiswa itu sendiri).
  def rotation_belongs_to_student
    return if clinical_rotation.nil? || student_id.nil? || clinical_rotation.user_id == student_id

    errors.add(:clinical_rotation, "bukan rotasi milik mahasiswa yang dinilai")
  end

  # Akun multi-peran (mis. dosen yang juga mahasiswa) tidak menilai dirinya
  # sendiri — sama dengan larangan memverifikasi kasus milik sendiri.
  def evaluator_is_not_student
    return if evaluator_id.nil? || evaluator_id != student_id

    errors.add(:student, "tidak boleh dinilai oleh dirinya sendiri")
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
