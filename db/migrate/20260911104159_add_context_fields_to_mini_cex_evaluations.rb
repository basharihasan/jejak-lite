class AddContextFieldsToMiniCexEvaluations < ActiveRecord::Migration[8.1]
  def up
    add_column :mini_cex_evaluations, :status, :string, default: "submitted", null: false
    add_column :mini_cex_evaluations, :clinical_setting, :string
    add_column :mini_cex_evaluations, :patient_age_group, :string
    add_column :mini_cex_evaluations, :case_complexity, :string
    add_column :mini_cex_evaluations, :observation_minutes, :integer
    add_column :mini_cex_evaluations, :feedback_minutes, :integer
    add_column :mini_cex_evaluations, :video_recording_url, :string
    add_column :mini_cex_evaluations, :global_rating, :string

    # global_rating dulunya tidak ada (skor "kompetensi_keseluruhan" masih
    # jadi dimensi numerik biasa) — evaluasi lama diberi nilai tengah supaya
    # validasi presence baru tidak merusak data yang sudah ada.
    safety_assured do
      execute "UPDATE mini_cex_evaluations SET global_rating = 'performed' WHERE global_rating IS NULL"
    end
  end

  def down
    remove_column :mini_cex_evaluations, :status
    remove_column :mini_cex_evaluations, :clinical_setting
    remove_column :mini_cex_evaluations, :patient_age_group
    remove_column :mini_cex_evaluations, :case_complexity
    remove_column :mini_cex_evaluations, :observation_minutes
    remove_column :mini_cex_evaluations, :feedback_minutes
    remove_column :mini_cex_evaluations, :video_recording_url
    remove_column :mini_cex_evaluations, :global_rating
  end
end
