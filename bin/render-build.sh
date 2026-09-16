#!/usr/bin/env bash
# Skrip build untuk Render (native Ruby runtime, bukan Docker) — dipanggil
# otomatis lewat buildCommand di render.yaml.
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:prepare
bundle exec rails db:seed

# Bootstrap akun admin pertama. Plan free Render tidak menyediakan akses
# shell, sehingga ini satu-satunya jalan membuat admin awal. Berjalan hanya
# bila ADMIN_EMAIL dan ADMIN_PASSWORD diisi di dashboard; tugasnya idempoten.
# KOSONGKAN ADMIN_PASSWORD setelah deploy pertama agar kata sandi tidak
# di-reset ulang pada setiap deploy berikutnya.
if [ -n "${ADMIN_EMAIL}" ] && [ -n "${ADMIN_PASSWORD}" ]; then
  bundle exec rails users:create_admin
fi
