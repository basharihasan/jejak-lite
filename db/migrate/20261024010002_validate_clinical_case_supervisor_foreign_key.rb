# Kolom supervisor_id baru dibuat dan masih NULL semua, jadi validasi ini
# tidak memindai apa pun — tapi FK yang tervalidasi tetap dijaga Postgres.
class ValidateClinicalCaseSupervisorForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :clinical_cases, :users, column: :supervisor_id
  end
end
