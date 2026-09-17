# frozen_string_literal: true

# Halaman ringkasan DOPS + Mini-CEX — dua instrumen berbeda tapi mahasiswa
# ingin melihatnya dalam satu tempat, mirip pola JEJAK (Asesmen Tahap
# Akademik & Profesi).
class AssessmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    dops_scope = policy_scope(DopsEvaluation).includes(:student, :evaluator)
    mini_cex_scope = policy_scope(MiniCexEvaluation).includes(:student, :evaluator)

    @draft_dops_evaluations = dops_scope.pending_for_evaluator.where(evaluator: current_user).recent
    @draft_mini_cex_evaluations = mini_cex_scope.pending_for_evaluator.where(evaluator: current_user).recent
    @my_requests = (dops_scope.requested.where(student: current_user).to_a +
                    mini_cex_scope.requested.where(student: current_user).to_a).sort_by(&:created_at).reverse

    # Dari Dasbor Mahasiswa: hanya evaluasi mahasiswa itu (tetap dalam policy_scope).
    if viewing_other_student?
      dops_scope = dops_scope.where(student: viewed_student)
      mini_cex_scope = mini_cex_scope.where(student: viewed_student)
    end
    @dops_evaluations = dops_scope.submitted.recent.limit(10)
    @mini_cex_evaluations = mini_cex_scope.submitted.recent.limit(10)
  end
end
