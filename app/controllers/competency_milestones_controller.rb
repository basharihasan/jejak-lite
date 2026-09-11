# frozen_string_literal: true

# Target skor per domain per periode — dikelola inline dari baris domain di
# halaman detail CompetencyFramework, pola sama seperti tambah ranah/mapping.
class CompetencyMilestonesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_competency_item

  def create
    authorize CompetencyMilestone
    milestone = @competency_item.competency_milestones.new(milestone_params)

    if milestone.save
      redirect_to competency_framework_path(@competency_item.competency_framework), notice: "Target kompetensi ditambahkan."
    else
      redirect_to competency_framework_path(@competency_item.competency_framework), alert: milestone.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize CompetencyMilestone
    milestone = @competency_item.competency_milestones.find(params[:id])
    milestone.destroy
    redirect_to competency_framework_path(@competency_item.competency_framework), notice: "Target kompetensi dihapus.", status: :see_other
  end

  private

  def set_competency_item
    @competency_item = CompetencyItem.find(params[:competency_item_id])
  end

  def milestone_params
    params.require(:competency_milestone).permit(:academic_period_id, :expected_score)
  end
end
