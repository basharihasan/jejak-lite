# frozen_string_literal: true

# Event asesmen — satu ujian/penilaian pada satu periode, opsional dibatasi
# prodi dan blok/stase. Nilainya masuk lewat impor CSV (CBT/OSCE/Progress
# Test), lembar penguji (rubrik), atau inisiasi dari kasus (CBD/Long Case).
# Meniru AssessmentEvent + AcademicAssessment.assessment_type jejak.pro,
# dipersempit ke instrumen Paket Dasar (DAFTAR_FITUR_JEJAK.md § Pilar B).
class AssessmentEvent < ApplicationRecord
  # tipe => [label, keluarga, prodi lazim]
  TYPES = {
    "cbt"                => [ "Ujian Tulis / CBT",            :written,  %w[pssk pspd] ],
    "tutor"              => [ "Nilai Tutor",                  :written,  %w[pssk] ],
    "tinjauan"           => [ "Ujian Tinjauan",               :written,  %w[pssk pspd] ],
    "tmex"               => [ "TMEX",                         :written,  %w[pssk pspd] ],
    "progress_test"      => [ "Progress Test",                :written,  %w[pssk pspd] ],
    "osce"               => [ "OSCE",                         :practical, %w[pssk pspd] ],
    "ebcr"               => [ "EBCR (Evidence-Based Case Report)", :rubric, %w[pspd] ],
    "soca_msp"           => [ "SOCA / MSP",                   :rubric,   %w[pssk] ],
    "essay_gagasan"      => [ "Essay Gagasan",                :rubric,   %w[pssk] ],
    "festival_gagasan"   => [ "Festival Gagasan",             :rubric,   %w[pssk] ],
    "community_project"  => [ "Community Project",            :rubric,   %w[pssk] ],
    "student_reflection" => [ "Refleksi Mahasiswa (dinilai)", :rubric,   %w[pssk pspd] ],
    "cbd"                => [ "Case-Based Discussion (CBD)",  :case,     %w[pspd] ],
    "long_case"          => [ "Long Case",                    :case,     %w[pspd] ]
  }.freeze
  STATUSES = { "draft" => "Draf", "published" => "Terbit", "closed" => "Ditutup" }.freeze
  FAMILY_LABELS = { written: "Ujian tulis", practical: "Ujian praktik", rubric: "Rubrik penguji", case: "Berbasis kasus" }.freeze

  belongs_to :academic_period
  belongs_to :study_program, optional: true
  belongs_to :assessment_form_template, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :assessment_instances, dependent: :destroy
  # Mata uji CBT / station OSCE beserta pemetaannya ke ranah kompetensi.
  has_many :assessment_dimensions, -> { ordered }, dependent: :destroy, inverse_of: :assessment_event
  # Baris Assessment Matrix unit pembelajaran yang menunjuk event ini.
  has_many :assessment_mappings, dependent: :destroy

  validates :name, presence: true
  validates :assessment_type, inclusion: { in: TYPES.keys }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :max_score, numericality: { greater_than: 0 }

  scope :published, -> { where(status: "published") }
  scope :ordered, -> { order(exam_date: :desc, created_at: :desc) }
  scope :of_type, ->(t) { where(assessment_type: t) }
  scope :for_student, ->(user) {
    published.where(study_program_id: [ nil, user.study_program_id ])
  }

  def type_label = TYPES.dig(assessment_type, 0) || assessment_type
  def family = TYPES.dig(assessment_type, 1)
  def status_label = STATUSES.fetch(status, status)
  def family_label = FAMILY_LABELS[family]

  # Mahasiswa mengunggah dokumen/evaluasi diri lalu penguji menilai.
  def requires_submission?
    %i[rubric].include?(family)
  end

  # Diinisiasi dari kasus logbook (CBD, Long Case).
  def case_based?
    family == :case
  end

  # Nilai masuk lewat impor CSV massal (ujian tulis/praktik).
  def importable?
    %i[written practical].include?(family)
  end

  # Event berdimensi: nilainya disusun dari nilai per mata uji/station.
  def dimension_based?
    assessment_dimensions.any?
  end

  def mapped_dimension_count
    assessment_dimensions.count(&:mapped?)
  end

  def submission_open?
    status == "published" && (submission_close_at.nil? || submission_close_at > Time.current)
  end

  # Event tampil untuk mahasiswa bila prodinya cocok DAN (tanpa blok, atau
  # blok cocok dengan enrolment tutorial / rotasi aktifnya).
  def visible_to?(user)
    return false unless status == "published"
    return false if study_program_id.present? && user.study_program_id != study_program_id
    return true if block_name.blank?

    blocks = user.tutorial_enrollments.active.pluck(:block_name) +
             user.clinical_rotations.ongoing.pluck(:station_name)
    blocks.map(&:downcase).include?(block_name.downcase)
  end

  def self.types_for_select
    TYPES.map { |code, (label, family, _)| [ "#{label} — #{FAMILY_LABELS[family]}", code ] }
  end
end
