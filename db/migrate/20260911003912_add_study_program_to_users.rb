# frozen_string_literal: true

class AddStudyProgramToUsers < ActiveRecord::Migration[8.1]
  def change
    # Opsional: hanya mahasiswa yang punya prodi, dosen/admin tidak.
    safety_assured { add_reference :users, :study_program, foreign_key: true }
  end
end
