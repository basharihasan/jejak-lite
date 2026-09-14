# frozen_string_literal: true

# Dua program studi tetap dari db/seeds.rb — Sarjana Kedokteran (pssk) dan
# Profesi Dokter (pspd) — bukan hierarki Faculty/University seperti JEJAK.
# Kode & jenjang mengikuti StudyProgram JEJAK supaya instrumen asesmen
# (Fase 25) bisa dibedakan per jenjang.
class StudyProgram < ApplicationRecord
  LEVELS = { "sarjana" => "Sarjana", "profesi" => "Profesi" }.freeze

  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "hanya huruf kecil, angka, dan tanda hubung" }
  validates :level, inclusion: { in: LEVELS.keys }

  scope :ordered, -> { order(:level, :name) }

  def level_label
    LEVELS.fetch(level, level)
  end

  def sarjana?
    level == "sarjana"
  end

  def profesi?
    level == "profesi"
  end
end
