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

  # Logo AIPKI (sponsor pengembangan) dibaca dari public/branding. Berkasnya
  # disimpan manual oleh pemilik aset; kalau belum ada, partial
  # shared/_aipki_logo jatuh ke wordmark teks alih-alih gambar rusak.
  AIPKI_LOGO_CANDIDATES = %w[aipki-logo.png aipki-logo.webp aipki-logo.jpg aipki-logo.svg].freeze

  def aipki_logo_path
    name = AIPKI_LOGO_CANDIDATES.find { |f| Rails.public_path.join("branding", f).exist? }
    name && "/branding/#{name}"
  end

  # Logo Diktisaintek Berdampak (sponsor pengembangan, berdampingan dengan
  # AIPKI). Tanpa cadangan teks: bila berkasnya tidak ada, logo tidak tampil.
  DIKTISAINTEK_LOGO_FILE = "Primary_Horizontal-Logo.png"

  def diktisaintek_logo_path
    "/branding/#{DIKTISAINTEK_LOGO_FILE}" if Rails.public_path.join("branding", DIKTISAINTEK_LOGO_FILE).exist?
  end
end
