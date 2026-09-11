# frozen_string_literal: true

class ExamScoresController < ApplicationController
  before_action :authenticate_user!

  def index
    scores = ExamScore.where(student: current_user).chronological
    @scores_by_kind = ExamImport::KINDS.keys.index_with { |kind| scores.for_kind(kind) }
  end
end
