# frozen_string_literal: true

# Cuma 2 baris tetap: Sarjana Kedokteran & Profesi Dokter (lihat db/seeds.rb)
# — bukan hierarki Faculty/University seperti JEJAK.
class StudyProgram < ApplicationRecord
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: true
end
