# frozen_string_literal: true

class AssessmentFormSubmission < ApplicationRecord
  belongs_to :assessment_form_template
  belongs_to :respondent, class_name: "User"
  belongs_to :subject_user, class_name: "User", optional: true

  has_many :assessment_form_answers, dependent: :destroy
  # Satu lembar rubrik dapat menjadi dasar nilai satu percobaan asesmen.
  has_one :assessment_instance, dependent: :nullify

  accepts_nested_attributes_for :assessment_form_answers

  validates :submitted_at, presence: true
  validate :subject_present_if_required
  validate :all_required_fields_answered

  scope :recent, -> { order(submitted_at: :desc) }

  # Identitas responden disembunyikan dari subjek yang dinilai kalau
  # template ditandai anonim — admin tetap bisa melihat (akuntabilitas),
  # meniru gerbang reveal_identity JEJAK tanpa membangun UI reveal terpisah.
  def respondent_visible_to?(user)
    return true unless assessment_form_template.anonymous?
    return true if user.has_role?("admin")
    return true if user == respondent

    subject_user.nil? || subject_user != user
  end

  def answer_for(field)
    assessment_form_answers.detect { |a| a.assessment_form_field_id == field.id }
  end

  # Nilai rubrik dalam persen: rata-rata TERBOBOT pertanyaan bertipe skor yang
  # terisi. nil bila rubrik tidak punya pertanyaan skor sama sekali —
  # kuesioner naratif memang tidak menghasilkan nilai.
  def score_percentage
    weighted = 0.0
    total_weight = 0.0
    assessment_form_answers.includes(:assessment_form_field).each do |answer|
      next unless answer.scorable?

      normalized = answer.numeric_value
      next if normalized.nil?

      weight = answer.assessment_form_field.weight.to_f
      weighted += normalized * weight
      total_weight += weight
    end
    return nil if total_weight.zero?

    ((weighted / total_weight) * 100).round(1)
  end

  def scorable?
    assessment_form_template.assessment_form_fields.any?(&:scorable?)
  end

  private

  def subject_present_if_required
    return unless assessment_form_template&.requires_subject_user?
    return if subject_user.present?

    errors.add(:subject_user, "wajib dipilih untuk formulir ini")
  end

  # Penjaga sisi model: sebelumnya pertanyaan wajib yang parameternya TIDAK
  # terkirim (mis. radio tak dipilih) lolos begitu saja karena tidak ada baris
  # jawaban untuk divalidasi — formulir tersimpan tanpa satu pun jawaban.
  def all_required_fields_answered
    return if assessment_form_template.nil?

    answered_ids = assessment_form_answers.reject { |a| a.value.blank? }.map(&:assessment_form_field_id)
    missing = assessment_form_template.assessment_form_fields.ordered.select { |f| f.required? && !answered_ids.include?(f.id) }
    return if missing.empty?

    errors.add(:base, "Pertanyaan wajib belum dijawab: #{missing.map(&:label).to_sentence}")
  end
end
