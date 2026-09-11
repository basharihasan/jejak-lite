# frozen_string_literal: true

class AssessmentFormSubmission < ApplicationRecord
  belongs_to :assessment_form_template
  belongs_to :respondent, class_name: "User"
  belongs_to :subject_user, class_name: "User", optional: true

  has_many :assessment_form_answers, dependent: :destroy
  accepts_nested_attributes_for :assessment_form_answers

  validates :submitted_at, presence: true
  validate :subject_present_if_required

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

  private

  def subject_present_if_required
    return unless assessment_form_template&.requires_subject_user?
    return if subject_user.present?

    errors.add(:subject_user, "wajib dipilih untuk formulir ini")
  end
end
