source "https://rubygems.org"

gem "dotenv-rails", groups: [ :development, :test ]

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
# json 3.x memutus ActiveSupport::JSON.decode (dipakai dekripsi cookie sesi)
# di Rails 8.1.3.1 — kunci ke seri 2.x yang terbukti kompatibel.
gem "json", "~> 2.7"
# Terjemahan Indonesia bawaan (time_ago_in_words, pesan validasi, dsb) — UI
# aplikasi ini seluruhnya berbahasa Indonesia, jangan biarkan string Rails
# default nyelip Inggris.
gem "rails-i18n"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 2.2"
gem "ruby-vips"

# ── Auth ──────────────────────────────────────────────────────────────────────
gem "devise"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# ── Authorization ─────────────────────────────────────────────────────────────
gem "pundit"

# ── UI / dashboard ────────────────────────────────────────────────────────────
gem "chartkick"
gem "groupdate"
gem "kaminari"

# ── Fitur Dasar ───────────────────────────────────────────────────────────────
gem "rqrcode"       # QR profil & QR pasien
gem "kramdown"       # render Panduan Pengguna
gem "web-push"       # notifikasi push
gem "discard"        # soft-delete logbook/evaluasi
gem "active_storage_validations"
gem "csv"            # import CBT/OSCE generik

# ── Hardening dasar ───────────────────────────────────────────────────────────
gem "rack-attack"
gem "rack-timeout"
gem "strong_migrations"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
