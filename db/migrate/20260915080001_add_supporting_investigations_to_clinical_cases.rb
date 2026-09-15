# Pemeriksaan penunjang (laboratorium, radiologi/pencitraan, lainnya) —
# langkah "Pemeriksaan Penunjang" wizard Kasus Klinis (Paket Dasar Pilar A).
class AddSupportingInvestigationsToClinicalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :clinical_cases, :laboratory_results, :text
    add_column :clinical_cases, :radiology_results, :text
    add_column :clinical_cases, :other_investigations, :text
  end
end
