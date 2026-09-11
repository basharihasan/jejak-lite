# frozen_string_literal: true

# Simpul pohon kompetensi (domain atau sub-kompetensi) — selalu dibuat/
# dihapus dari halaman detail CompetencyFramework, tidak punya halaman
# sendiri (index/show terpisah tidak diperlukan untuk pohon sesederhana ini).
class CompetencyItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_competency_framework
  before_action :set_competency_item, only: %i[destroy]

  def create
    authorize CompetencyItem
    @competency_item = @competency_framework.competency_items.new(competency_item_params)

    if @competency_item.save
      redirect_to competency_framework_path(@competency_framework), notice: "Simpul kompetensi ditambahkan."
    else
      redirect_to competency_framework_path(@competency_framework), alert: @competency_item.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize @competency_item
    @competency_item.destroy
    redirect_to competency_framework_path(@competency_framework), notice: "Simpul kompetensi dihapus.", status: :see_other
  end

  private

  def set_competency_framework
    @competency_framework = CompetencyFramework.find(params[:competency_framework_id])
  end

  def set_competency_item
    @competency_item = @competency_framework.competency_items.find(params[:id])
  end

  def competency_item_params
    params.require(:competency_item).permit(:title, :description, :parent_id)
  end
end
