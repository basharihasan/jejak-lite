# frozen_string_literal: true

# Jurnal Umpan Balik Penguji — seluruh umpan balik tertulis (rubrik, CBD/Long
# Case, DOPS, Mini-CEX) dalam satu linimasa kronologis, ala jejak.pro.
class Student::FeedbackJournalController < ApplicationController
  before_action :authenticate_user!

  def index
    entries = []
    current_user.assessment_instances.scored.includes(:assessment_event, :examiner).each do |i|
      next unless i.has_feedback?

      entries << { at: i.scored_at, kind: i.type_label, title: i.assessment_event.name, by: i.examiner&.full_name,
                   keep: i.feedback_keep, improve: i.feedback_improve, score: i.percentage }
    end
    current_user.dops_evaluations_as_student.submitted.includes(:evaluator).each do |e|
      next if e.overall_feedback.blank?

      entries << { at: e.evaluated_at.to_time, kind: "DOPS", title: e.procedure_name, by: e.evaluator.full_name,
                   keep: nil, improve: e.overall_feedback, score: e.average_score }
    end
    current_user.mini_cex_evaluations_as_student.submitted.includes(:evaluator).each do |e|
      next if e.overall_feedback.blank?

      entries << { at: e.evaluated_at.to_time, kind: "Mini-CEX", title: e.case_description.to_s.truncate(60), by: e.evaluator.full_name,
                   keep: nil, improve: e.overall_feedback, score: e.average_score }
    end
    @entries = entries.sort_by { |e| e[:at] || Time.at(0) }.reverse
  end
end
