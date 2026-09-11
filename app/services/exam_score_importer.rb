# frozen_string_literal: true

require "csv"

# Importer CSV generik untuk CBT/OSCE/Progress Test — BUKAN integrasi Glide
# seperti JEJAK, karena Jejak Lite berdiri sendiri lepas dari institusi asal
# JEJAK. Format kolom: email,score,exam_date,max_score(opsional, default 100).
class ExamScoreImporter
  Result = Struct.new(:exam_import, :imported_count, :unmatched_emails, :errors, keyword_init: true)

  def initialize(kind:, name:, csv_text:, imported_by:)
    @kind = kind
    @name = name
    @csv_text = csv_text
    @imported_by = imported_by
  end

  def call
    exam_import = ExamImport.create!(kind: @kind, name: @name, imported_by: @imported_by)
    imported = 0
    unmatched = []
    errors = []

    CSV.parse(@csv_text, headers: true, header_converters: :symbol).each_with_index do |row, idx|
      email = row[:email].to_s.strip.downcase
      student = User.find_by(email: email)

      if student.nil?
        unmatched << email
        next
      end

      score = ExamScore.new(
        exam_import: exam_import,
        student: student,
        score: row[:score],
        max_score: row[:max_score].presence || 100,
        exam_date: row[:exam_date]
      )

      if score.save
        imported += 1
      else
        errors << "Baris #{idx + 2} (#{email}): #{score.errors.full_messages.to_sentence}"
      end
    end

    exam_import.update!(row_count: imported, unmatched_count: unmatched.size)
    Result.new(exam_import: exam_import, imported_count: imported, unmatched_emails: unmatched.uniq, errors: errors)
  end
end
