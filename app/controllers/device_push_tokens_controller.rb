# frozen_string_literal: true

class DevicePushTokensController < ApplicationController
  before_action :authenticate_user!, except: [ :public_key ]

  # Kunci publik VAPID dibaca browser sebelum subscribe — aman diekspos,
  # beda dari private key yang cuma dipakai server saat kirim (job).
  def public_key
    render json: { publicKey: ENV["VAPID_PUBLIC_KEY"] }
  end

  def create
    subscription = params.require(:subscription).permit(:endpoint, keys: [ :p256dh, :auth ])
    token = current_user.device_push_tokens.find_or_initialize_by(endpoint: subscription[:endpoint])
    token.assign_attributes(
      p256dh_key: subscription.dig(:keys, :p256dh),
      auth_key: subscription.dig(:keys, :auth)
    )

    if token.save
      head :created
    else
      render json: { errors: token.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.device_push_tokens.where(endpoint: params[:endpoint]).destroy_all
    head :no_content
  end
end
