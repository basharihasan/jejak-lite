require "test_helper"

# Layanan Active Storage "cloudflare" (config/storage.yml) dibangun dari
# variabel R2_* — tanpa memanggil jaringan, cukup memastikan klien S3-nya
# menunjuk ke endpoint R2 dengan pengaturan yang diterima R2.
class R2StorageConfigTest < ActiveSupport::TestCase
  R2_ENV = {
    "R2_ACCOUNT_ID" => "acct0123456789", "R2_ACCESS_KEY_ID" => "uji-akses",
    "R2_SECRET_ACCESS_KEY" => "uji-rahasia", "R2_BUCKET" => "jejak-lite-uji"
  }.freeze

  def with_r2_env
    previous = R2_ENV.keys.index_with { |key| ENV[key] }
    R2_ENV.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  test "layanan cloudflare menunjuk ke endpoint R2 akun dengan region auto" do
    with_r2_env do
      configs = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/storage.yml")).deep_symbolize_keys
      service = ActiveStorage::Service.configure(:cloudflare, configs)

      assert_kind_of ActiveStorage::Service::S3Service, service
      assert_equal "jejak-lite-uji", service.bucket.name
      config = service.client.client.config
      assert_equal "acct0123456789.r2.cloudflarestorage.com", config.endpoint.host
      assert_equal "auto", config.region
      assert_equal "uji-akses", config.credentials.access_key_id
      # R2 menolak checksum CRC32 bawaan SDK baru.
      assert_equal "when_required", config.request_checksum_calculation
      assert_equal "when_required", config.response_checksum_validation
    end
  end

  test "tanpa R2_BUCKET, layanan cloudflare tidak ikut dibangun saat boot" do
    assert_nil ENV["R2_BUCKET"].presence
    assert_equal :test, Rails.application.config.active_storage.service
  end
end
