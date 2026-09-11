# frozen_string_literal: true

# Form Builder generik — infrastruktur untuk asesmen yang bentuknya beda-beda
# per institusi (Tutor Evaluation, Evaluasi Blok, asesmen tambahan, Fase 10).
# BUKAN untuk DOPS/Mini-CEX (Fase 8) yang rubriknya baku secara internasional.
class AssessmentFormTemplate < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :assessment_form_fields, -> { order(:position) }, dependent: :destroy, inverse_of: :assessment_form_template
  has_many :assessment_form_submissions, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
end
