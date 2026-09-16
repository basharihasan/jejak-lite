# frozen_string_literal: true

# Membuat/mereset akun admin PRODUKSI — BUKAN akun demo password publik
# (lihat demo.rake). Kredensial diambil dari ENV supaya tidak pernah
# ter-hardcode di kode/log:
#
#   ADMIN_EMAIL=admin@instansi.id \
#   ADMIN_PASSWORD='kata-sandi-kuat' \
#   ADMIN_NAME='Administrator' \
#   bin/rails users:create_admin
#
# Di QNAP Container Station: kontainer `web` -> Terminal/Exec, jalankan
# perintah di atas. Idempoten: aman diulang (memperbarui password bila akun
# sudah ada). Jalankan `bin/rails db:seed` lebih dulu bila peran belum ada.
namespace :users do
  desc "Buat/reset akun admin produksi dari ENV ADMIN_EMAIL/ADMIN_PASSWORD/ADMIN_NAME"
  task create_admin: :environment do
    email    = ENV["ADMIN_EMAIL"].to_s.strip.downcase
    password = ENV["ADMIN_PASSWORD"].to_s
    name     = ENV["ADMIN_NAME"].to_s.strip.presence || "Administrator"

    abort "ADMIN_EMAIL wajib diisi." if email.empty?
    abort "ADMIN_PASSWORD wajib minimal 8 karakter." if password.length < 8

    admin_role = Role.find_or_create_by!(code: "admin") { |r| r.name = "Admin" }

    user = User.find_or_initialize_by(email: email)
    baru = user.new_record?
    user.full_name = name if user.full_name.blank?
    user.password = password
    user.password_confirmation = password
    user.confirmed_at ||= Time.current if user.respond_to?(:confirmed_at)
    user.save!

    user.roles << admin_role unless user.has_role?("admin")
    user.update!(active_role: admin_role) if user.active_role.nil?

    puts(baru ? "Admin DIBUAT: #{email}" : "Admin DIPERBARUI (password direset): #{email}")
    puts "Peran: #{user.roles.pluck(:code).join(', ')}"
  end
end
