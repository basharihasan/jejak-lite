# Kolom penautnya baru dibuat dan masih NULL semua, jadi validasi ini tidak
# memindai apa pun — tapi FK yang tervalidasi tetap dijaga Postgres untuk
# baris lama maupun baru.
class ValidateActivityLogTaxonomyForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :activity_logs, :academic_activity_domains
    validate_foreign_key :activity_logs, :academic_activity_subdomains
    validate_foreign_key :activity_logs, :academic_activity_templates
    validate_foreign_key :activity_logs, :academic_periods
    validate_foreign_key :activity_logs, :clinical_rotations
  end
end
