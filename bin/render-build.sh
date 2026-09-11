#!/usr/bin/env bash
# Skrip build untuk Render (native Ruby runtime, bukan Docker) — dipanggil
# otomatis lewat buildCommand di render.yaml.
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:prepare
bundle exec rails db:seed
