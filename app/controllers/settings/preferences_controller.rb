# frozen_string_literal: true

# Pengaturan Saya — preferensi tampilan (tema & ukuran huruf) milik pengguna
# sendiri. Tidak ada otorisasi per-record: pengguna hanya pernah membaca dan
# menulis preferensinya sendiri, jadi Pundit tidak dipakai di sini.
class Settings::PreferencesController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  # Melayani dua pemanggil: form penuh di halaman Pengaturan (HTML) dan tombol
  # siklus tema di topbar (fetch JSON) yang hanya perlu perubahannya tersimpan.
  def update_appearance
    if current_user.update(appearance_params)
      respond_to do |format|
        format.html { redirect_to my_settings_path, notice: "Preferensi tampilan berhasil disimpan." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def appearance_params
    params.require(:user).permit(:theme_preference, :font_size_preference)
  end
end
