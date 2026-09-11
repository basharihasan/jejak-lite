# frozen_string_literal: true

class ExamImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exam_import, only: %i[show destroy]

  def index
    authorize ExamImport
    @exam_imports = ExamImport.recent.includes(:imported_by)
  end

  def new
    authorize ExamImport
  end

  def create
    authorize ExamImport
    file = params[:file]

    if file.blank?
      flash.now[:alert] = "Pilih berkas CSV terlebih dahulu."
      return render :new, status: :unprocessable_entity
    end

    result = ExamScoreImporter.new(
      kind: params[:kind], name: params[:name].presence || file.original_filename,
      csv_text: file.read, imported_by: current_user
    ).call

    @import_result = result
    render :result
  end

  def show
    authorize @exam_import
    @exam_scores = @exam_import.exam_scores.includes(:student).order(:exam_date)
  end

  def destroy
    authorize @exam_import
    @exam_import.destroy
    redirect_to exam_imports_path, notice: "Batch impor dan semua skornya dihapus.", status: :see_other
  end

  private

  def set_exam_import
    @exam_import = ExamImport.find(params[:id])
  end
end
