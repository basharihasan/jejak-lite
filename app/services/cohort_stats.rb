# frozen_string_literal: true

# Rumus posisi kohort yang dipakai bersama CohortPercentileCalculator (per
# periode) dan AssessmentCohortProfile (per event).
module CohortStats
  module_function

  # Persentil = porsi kohort yang nilainya di bawah nilai saya (metode
  # "percentile rank", dibulatkan).
  def percentile_rank(sorted, value)
    below = sorted.count { |v| v < value }
    same = sorted.count { |v| v == value }
    (((below + (same / 2.0)) / sorted.size) * 100).round
  end

  # Interpolasi linear antar-titik, seperti kurva persentil kohort jejak.pro.
  def percentile_value(sorted, pct)
    return sorted.first if sorted.size == 1

    rank = (pct / 100.0) * (sorted.size - 1)
    low = sorted[rank.floor]
    high = sorted[rank.ceil]
    (low + ((high - low) * (rank - rank.floor))).round(1)
  end

  def mean(values)
    (values.sum / values.size.to_f).round(1)
  end
end
