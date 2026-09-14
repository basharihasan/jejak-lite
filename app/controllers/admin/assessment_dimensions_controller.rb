# frozen_string_literal: true

# Dimensi asesmen per event (mata uji CBT / station OSCE) beserta pemetaannya
# ke ranah kompetensi. Dari pemetaan inilah Peta Kompetensi mahasiswa terisi
# oleh hasil ujian, bukan proksi rata-rata.
class Admin::AssessmentDimensionsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_dimension, only: %i[update destroy]
  before_action :set_event

  def create
    dimension = @event.assessment_dimensions.new(dimension_params)
    if dimension.save
      redirect_to admin_assessment_event_path(@event, tab: "dimensi"), notice: "Dimensi #{dimension.label} ditambahkan."
    else
      redirect_to admin_assessment_event_path(@event, tab: "dimensi"), alert: dimension.errors.full_messages.to_sentence
    end
  end

  def update
    if @dimension.update(dimension_params)
      redirect_to admin_assessment_event_path(@event, tab: "dimensi"), notice: "Dimensi #{@dimension.label} diperbarui."
    else
      redirect_to admin_assessment_event_path(@event, tab: "dimensi"), alert: @dimension.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @dimension.assessment_dimension_scores.exists?
      redirect_to admin_assessment_event_path(@event, tab: "dimensi"),
                  alert: "Dimensi #{@dimension.label} sudah punya nilai mahasiswa. Hapus nilainya lewat impor ulang bila memang keliru."
      return
    end

    @dimension.destroy
    redirect_to admin_assessment_event_path(@event, tab: "dimensi"), notice: "Dimensi dihapus.", status: :see_other
  end

  # Petakan beberapa dimensi ke ranah kompetensi sekaligus dari satu tabel.
  def bulk_map
    mappings = params.fetch(:competency_item_ids, {}).to_unsafe_h
    updated = 0
    @event.assessment_dimensions.each do |dimension|
      next unless mappings.key?(dimension.id.to_s)

      value = mappings[dimension.id.to_s].presence
      next if dimension.competency_item_id.to_s == value.to_s

      dimension.update!(competency_item_id: value)
      updated += 1
    end
    redirect_to admin_assessment_event_path(@event, tab: "dimensi"),
                notice: "#{updated} pemetaan dimensi → kompetensi diperbarui."
  end

  private

  def require_admin!
    return if current_user.has_role?("admin")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin."
  end

  # Rute anggota bersifat shallow (/admin/assessment_dimensions/:id), jadi
  # event-nya diturunkan dari dimensi; rute koleksi tetap membawa event.
  def set_event
    @event = @dimension&.assessment_event || AssessmentEvent.find(params[:assessment_event_id])
  end

  def set_dimension
    @dimension = AssessmentDimension.find(params[:id])
  end

  def dimension_params
    params.require(:assessment_dimension).permit(:name, :code, :competency_item_id, :weight, :max_score)
  end
end
