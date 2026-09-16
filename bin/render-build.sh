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

# Akun & data demo untuk mencoba tiap peran. Tidak pernah jalan kecuali
# DEMO_SEED diisi, karena situs ini terbuka di internet. Isi DEMO_PASSWORD
# dengan kata sandi sendiri — tanpa itu akun demo memakai password123 yang
# tercantum publik di repositori.
if [ -n "${DEMO_SEED}" ]; then
  bundle exec rails demo:seed
fi
