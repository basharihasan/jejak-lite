# frozen_string_literal: true

# Satu batch impor CSV — dipakai bersama untuk CBT, OSCE, dan Progress Test
# (skema terpadu, bukan tiga pipeline terpisah seperti JEJAK) karena
# ketiganya sama-sama "daftar skor mahasiswa per tanggal ujian".
class ExamImport < ApplicationRecord
  KINDS = { "cbt" => "CBT", "osce" => "OSCE", "progress_test" => "Progress Test" }.freeze

  belongs_to :imported_by, class_name: "User"
  has_many :exam_scores, dependent: :destroy

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS.keys }

  scope :recent, -> { order(created_at: :desc) }

  def kind_label
    KINDS.fetch(kind, kind)
  end
end
