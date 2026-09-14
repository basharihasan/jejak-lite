# frozen_string_literal: true

# Pengaturan Saya — preferensi tampilan (tema, ukuran huruf, bahasa) milik
# pengguna sendiri. Tidak ada otorisasi per-record: pengguna hanya pernah
# membaca dan menulis preferensinya sendiri, jadi Pundit tidak dipakai di sini.
class Settings::PreferencesController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  # Melayani dua pemanggil: form penuh di halaman Pengaturan (HTML) dan tombol
  # siklus tema di topbar (fetch JSON) yang hanya perlu perubahannya tersimpan.
  def update_appearance
    if current_user.update(appearance_params)
      respond_to do |format|
        format.html { redirect_to my_settings_path, notice: t("settings.saved_appearance") }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # Tombol ganti bahasa di topbar — kembali ke halaman asal, bukan ke
  # /pengaturan, karena bisa dipanggil dari mana saja.
  def update_locale
    locale = params[:locale].to_s
    unless User::LOCALE_OPTIONS.include?(locale)
      redirect_back fallback_location: my_settings_path, alert: t("settings.unsupported_locale")
      return
    end

    current_user.update!(locale_preference: locale)
    cookies.permanent[:locale] = { value: locale, same_site: :lax }
    # Pesannya dipaksa ke bahasa BARU — I18n.locale untuk request ini sudah
    # ditetapkan around_action sebelum kolomnya berubah.
    redirect_back fallback_location: my_settings_path,
                  notice: I18n.with_locale(locale) { t("settings.saved_locale", language: t("settings.language_#{locale}")) }
  end

  private

  def appearance_params
    params.require(:user).permit(:theme_preference, :font_size_preference, :locale_preference)
  end
end
