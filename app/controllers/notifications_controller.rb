# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: %i[mark_as_read archive]

  def index
    @notifications = current_user.notifications.active.recent.page(params[:page])
  end

  def mark_as_read
    @notification.mark_as_read!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: notifications_path }
    end
  end

  def archive
    @notification.archive!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: notifications_path }
    end
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: notifications_path }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
