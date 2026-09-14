# frozen_string_literal: true

# Kunci Active Record Encryption untuk kolom identitas pasien (ClinicalCase:
# nama, No. RM, tanggal lahir, telepon, alamat).
#
# Urutan sumber kunci:
#   1. ENV AR_ENCRYPTION_PRIMARY_KEY / _DETERMINISTIC_KEY / _KEY_DERIVATION_SALT
#      (dianjurkan untuk self-hosted: kunci di luar repo & di luar credentials).
#   2. credentials.active_record_encryption (bila diisi lewat bin/rails credentials:edit).
#   3. development/test saja: diturunkan dari secret_key_base supaya lingkungan
#      lokal dan CI jalan tanpa setup. Di production tanpa (1)/(2) aplikasi
#      MENOLAK boot — data pasien tidak boleh dienkripsi dengan kunci yang
#      bisa ditebak dari kode.
Rails.application.configure do
  env_keys = {
    primary_key: ENV["AR_ENCRYPTION_PRIMARY_KEY"],
    deterministic_key: ENV["AR_ENCRYPTION_DETERMINISTIC_KEY"],
    key_derivation_salt: ENV["AR_ENCRYPTION_KEY_DERIVATION_SALT"]
  }
  cred_keys = Rails.application.credentials.active_record_encryption&.to_h&.symbolize_keys || {}

  keys =
    if env_keys.values.all?(&:present?)
      env_keys
    elsif %i[primary_key deterministic_key key_derivation_salt].all? { |k| cred_keys[k].present? }
      cred_keys
    elsif Rails.env.local?
      gen = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1000)
      {
        primary_key: gen.generate_key("ar-encryption-primary", 32).unpack1("H*")[0, 32],
        deterministic_key: gen.generate_key("ar-encryption-deterministic", 32).unpack1("H*")[0, 32],
        key_derivation_salt: gen.generate_key("ar-encryption-salt", 32).unpack1("H*")[0, 32]
      }
    else
      raise "Kunci Active Record Encryption belum disetel. Isi ENV AR_ENCRYPTION_PRIMARY_KEY, " \
            "AR_ENCRYPTION_DETERMINISTIC_KEY, AR_ENCRYPTION_KEY_DERIVATION_SALT " \
            "(hasil `bin/rails db:encryption:init`) atau credentials.active_record_encryption."
    end

  config.active_record.encryption.primary_key = keys[:primary_key]
  config.active_record.encryption.deterministic_key = keys[:deterministic_key]
  config.active_record.encryption.key_derivation_salt = keys[:key_derivation_salt]
end
