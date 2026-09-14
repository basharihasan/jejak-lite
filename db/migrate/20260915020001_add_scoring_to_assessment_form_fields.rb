class AddScoringToAssessmentFormFields < ActiveRecord::Migration[8.1]
  # Form Builder dipakai sebagai RUBRIK penilaian (Assessment Event bertipe
  # rubrik), bukan sekadar kuesioner: setiap pertanyaan bertipe skor punya
  # skala (max_score) dan bobot, sehingga nilai akhir bisa dihitung dari
  # jawaban penguji — sebelumnya rubrik hanya hiasan dan nilai diketik ulang.
  def change
    add_column :assessment_form_fields, :max_score, :integer, null: false, default: 5
    add_column :assessment_form_fields, :weight, :decimal, precision: 6, scale: 2, null: false, default: 1
    add_column :assessment_form_fields, :help_text, :string
  end
end
