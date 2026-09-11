# frozen_string_literal: true

# Halaman ringkasan DOPS + Mini-CEX — dua instrumen berbeda tapi mahasiswa
# ingin melihatnya dalam satu tempat, mirip pola JEJAK (Asesmen Tahap
# Akademik & Profesi).
class AssessmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    dops_scope = policy_scope(DopsEvaluation).includes(:student, :evaluator)
    mini_cex_scope = policy_scope(MiniCexEvaluation).includes(:student, :evaluator)

    @draft_dops_evaluations = dops_scope.draft.where(evaluator: current_user).recent
    @draft_mini_cex_evaluations = mini_cex_scope.draft.where(evaluator: current_user).recent

    @dops_evaluations = dops_scope.submitted.recent.limit(10)
    @mini_cex_evaluations = mini_cex_scope.submitted.recent.limit(10)
  end
end
