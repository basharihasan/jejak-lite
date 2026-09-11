# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Profil berhasil diperbarui."
    else
      @user = current_user
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:full_name, :avatar, :study_program_id)
  end
end
