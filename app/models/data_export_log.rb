# frozen_string_literal: true

# Satu unduhan dari Pusat Ekspor Data (DataExport) — dicatat setiap kali,
# supaya ekspor massal data mahasiswa selalu punya jejak audit.
class DataExportLog < ApplicationRecord
  belongs_to :user

  validates :dataset, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def dataset_label
    DataExport::DATASETS[dataset]&.label || dataset
  end
end
