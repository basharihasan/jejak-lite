# frozen_string_literal: true

# Halaman ringkasan DOPS + Mini-CEX — dua instrumen berbeda tapi mahasiswa
# ingin melihatnya dalam satu tempat, mirip pola JEJAK (Asesmen Tahap
# Akademik & Profesi).
class AssessmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @dops_evaluations = policy_scope(DopsEvaluation).includes(:student, :evaluator).recent.limit(10)
    @mini_cex_evaluations = policy_scope(MiniCexEvaluation).includes(:student, :evaluator).recent.limit(10)
  end
end
