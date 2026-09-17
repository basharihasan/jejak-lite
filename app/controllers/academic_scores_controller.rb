# frozen_string_literal: true

# Evaluasi Akademik (/nilai-ujian) — nilai saya per tipe asesmen dari
# AssessmentInstance (menggantikan halaman Nilai Ujian berbasis ExamScore).
class AcademicScoresController < ApplicationController
  before_action :authenticate_user!

  def index
    scored = current_user.assessment_instances.scored.includes(assessment_event: :academic_period)
    @by_type = scored.group_by(&:assessment_type).sort_by { |t, _| AssessmentEvent::TYPES.keys.index(t) || 99 }
    @pending = current_user.assessment_instances.awaiting_score.includes(:assessment_event).recent
    # Lencana persentil per baris; nil bila kohort event terlalu kecil.
    @positions = scored.to_h { |i| [ i.id, AssessmentCohortProfile.new(i).position ] }
  end
end
