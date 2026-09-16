# syntax=docker/dockerfile:1

# Dockerfile untuk deployment self-hosted (NAS, VPS, dsb.) — dipakai
# GitHub Actions (.github/workflows/docker-publish.yml) untuk membangun image
# multi-arsitektur (amd64 + arm64) yang ditarik langsung oleh Container
# Station/Portainer/dsb., bukan dibangun di NAS itu sendiri (banyak NAS
# terlalu lemah untuk bundle install + tailwindcss build).
#
# Dua tahap: "build" berisi toolchain kompilasi (dibuang di image akhir),
# "final" cuma berisi runtime + hasil bundle. Meniru pola Dockerfile bawaan
# `rails new` (Rails 7.1+), ditulis manual karena repo ini dibuat sebelum
# generator itu ada / Dockerfile-nya sempat dihapus.

ARG RUBY_VERSION=4.0.6
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

# Pustaka runtime: libpq (gem pg), libvips (ruby-vips/image_processing),
# curl (health check container, dan tailwindcss-rails perlu curl saat
# instalasi awal binary-nya kalau belum ter-vendor).
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 libvips curl && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# ── Tahap build ──────────────────────────────────────────────────────────
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libvips-dev pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY Gemfile Gemfile.lock ./
RUN bundle install --local || bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Jaring pengaman: skrip bin/* dulu sempat tercatat git tanpa bit
# executable (repo ini banyak dikerjakan di Windows) — chmod eksplisit di
# sini supaya build tidak lagi bergantung pada mode berkas yang tersimpan
# di git.
RUN chmod +x bin/*

# Kunci DUMMY khusus untuk precompile aset saat BUILD image — bukan kunci
# sungguhan (yang disuntik lewat docker-compose environment saat container
# jalan). config/initializers/active_record_encryption.rb cuma memeriksa
# kunci ADA (presence), bukan valid untuk enkripsi data sungguhan, dan
# precompile aset tidak pernah menyentuh data pasien — jadi nilai apa pun
# di sini aman, asal tidak dipakai ulang saat runtime produksi.
RUN SECRET_KEY_BASE_DUMMY=1 \
    AR_ENCRYPTION_PRIMARY_KEY=build-time-only-not-a-real-key-00000000 \
    AR_ENCRYPTION_DETERMINISTIC_KEY=build-time-only-not-a-real-key-00000000 \
    AR_ENCRYPTION_KEY_DERIVATION_SALT=build-time-only-not-a-real-key-00000000 \
    ./bin/rails assets:precompile

# ── Tahap akhir (runtime) ────────────────────────────────────────────────
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Pengguna non-root — image tidak pernah jalan sebagai root saat runtime.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp
USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server"]
