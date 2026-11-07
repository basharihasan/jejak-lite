# frozen_string_literal: true

# Domain akun contoh mengikuti nama aplikasi (User::DEMO_EMAIL_DOMAIN). Akun yang
# sudah ada ikut dipindahkan: tanpa ini akun lama kehilangan pengecualian wajib
# ganti kata sandi, dan demo:seed membuat akun kembar. Alamat tujuan yang sudah
# terpakai dilewati agar indeks unik email tidak terlanggar.
class RenameDemoEmailDomain < ActiveRecord::Migration[8.1]
  OLD_DOMAIN = "@jejaklite.test"
  NEW_DOMAIN = "@jejakessential.test"

  def up
    rename_domain(OLD_DOMAIN, NEW_DOMAIN)
  end

  def down
    rename_domain(NEW_DOMAIN, OLD_DOMAIN)
  end

  private

  def rename_domain(from, to)
    safety_assured do
      execute <<~SQL
        UPDATE users
        SET email = replace(users.email, '#{from}', '#{to}')
        WHERE users.email LIKE '%#{from}'
          AND NOT EXISTS (
            SELECT 1 FROM users AS existing
            WHERE existing.email = replace(users.email, '#{from}', '#{to}')
          )
      SQL
    end
  end
end
