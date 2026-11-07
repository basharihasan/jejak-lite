require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JejakEssential
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Asia/Jakarta"
    config.i18n.default_locale = :id
    config.i18n.available_locales = %i[id en]
    # Kunci yang belum diterjemahkan ke :en jatuh ke :id (dan sebaliknya), jadi
    # halaman tidak pernah menampilkan "translation missing".
    config.i18n.fallbacks = { en: :id, id: :en }
    # config.eager_load_paths << Rails.root.join("extras")

    # Rute bawaan Active Storage dimatikan: tautannya terbuka tanpa login dan
    # tidak kedaluwarsa, padahal bukti kasus bisa memuat foto pasien. Semua
    # unduhan lewat AttachmentsController yang memeriksa izin.
    config.active_storage.draw_routes = false
  end
end
