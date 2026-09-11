class MigrateVerificationCommentsAndDropColumn < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      # verification_comment lama (kolom tunggal, tertimpa tiap transisi)
      # dipindahkan jadi baris pertama riwayat case_verification_comments
      # SEBELUM kolomnya dihapus — supaya tidak ada catatan hilang.
      execute <<~SQL
        INSERT INTO case_verification_comments (clinical_case_id, user_id, action, body, created_at, updated_at)
        SELECT id,
               COALESCE(verified_by_id, user_id),
               CASE status WHEN 'verified' THEN 'verified' WHEN 'needs_revision' THEN 'revision_requested' ELSE 'verified' END,
               verification_comment,
               COALESCE(verified_at, created_at),
               COALESCE(verified_at, created_at)
        FROM clinical_cases
        WHERE verification_comment IS NOT NULL AND verification_comment <> ''
      SQL

      remove_column :clinical_cases, :verification_comment
    end
  end

  def down
    add_column :clinical_cases, :verification_comment, :text
  end
end
