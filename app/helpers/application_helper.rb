module ApplicationHelper
  # Pita warna skor 1-9 dipakai di banyak tempat (Asesmen, Dashboard
  # Analitik) — hijau >=7, kuning 4-6, merah <4, abu-abu kalau belum ada
  # data sama sekali. Dikembalikan sebagai class Tailwind literal (bukan
  # interpolasi) supaya lolos content-scan Tailwind.
  def score_band_classes(score)
    return "bg-gray-100 text-gray-500" if score.blank?

    case score.to_f
    when 7.. then "bg-emerald-50 text-emerald-700"
    when 4...7 then "bg-amber-50 text-amber-700"
    else "bg-rose-50 text-rose-700"
    end
  end
end
