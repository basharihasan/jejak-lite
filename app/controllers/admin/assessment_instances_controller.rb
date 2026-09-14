# frozen_string_literal: true

# Sunting satu percobaan dari halaman event: penguji, jadwal, nilai manual.
class Admin::AssessmentInstancesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_instance

  def update
    attrs = params.require(:assessment_instance).permit(:examiner_id, :scheduled_at, :score, :max_score, :feedback_keep, :feedback_improve)
    if attrs[:score].present?
      @instance.assign_attributes(attrs.merge(status: "scored", scored_at: Time.current, source: "manual"))
    else
      @instance.assign_attributes(attrs.except(:score))
    end

    if @instance.save
      redirect_to admin_assessment_event_path(@instance.assessment_event), notice: "Percobaan #{@instance.student.full_name} diperbarui."
    else
      redirect_to admin_assessment_event_path(@instance.assessment_event), alert: @instance.errors.full_messages.to_sentence
    end
  end

  def destroy
    event = @instance.assessment_event
    @instance.destroy
    redirect_to admin_assessment_event_path(event), notice: "Percobaan dihapus.", status: :see_other
  end

  private

  def require_admin!
    return if current_user.has_role?("admin")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin."
  end

  def set_instance
    @instance = AssessmentInstance.find(params[:id])
  end
end
