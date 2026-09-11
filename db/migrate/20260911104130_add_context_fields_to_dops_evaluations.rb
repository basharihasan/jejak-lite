class AddContextFieldsToDopsEvaluations < ActiveRecord::Migration[8.1]
  def change
    add_column :dops_evaluations, :status, :string, default: "submitted", null: false
    add_column :dops_evaluations, :clinical_setting, :string
    add_column :dops_evaluations, :patient_age_group, :string
    add_column :dops_evaluations, :case_complexity, :string
    add_column :dops_evaluations, :observation_minutes, :integer
    add_column :dops_evaluations, :feedback_minutes, :integer
    add_column :dops_evaluations, :video_recording_url, :string
  end
end
