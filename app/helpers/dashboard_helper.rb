# frozen_string_literal: true

# Pemformatan Beranda — kartu "Agenda Mendatang" (DashboardController::AgendaItem)
# dan kelas warna yang dipakai beberapa panel. Kelas Tailwind ditulis literal
# supaya terbaca pemindai Tailwind dan ditangani retrofit mode gelap.
module DashboardHelper
  # Banyaknya butir yang DITAMPILKAN; controller menarik sampai AGENDA_LIMIT (8)
  # supaya sisanya bisa ditulis "+N agenda lainnya".
  AGENDA_DISPLAY_LIMIT = 5

  AGENDA_KIND_DOTS = {
    kegiatan:  "bg-indigo-500",
    rotasi:    "bg-emerald-500",
    tutorial:  "bg-sky-500",
    penilaian: "bg-amber-500",
    ujian:     "bg-rose-500",
    tenggat:   "bg-amber-600",
    tugas:     "bg-violet-500"
  }.freeze

  AGENDA_STATUS_CLASSES = {
    slate:   "bg-slate-50 text-slate-700 ring-slate-600/20",
    indigo:  "bg-indigo-50 text-indigo-700 ring-indigo-600/20",
    sky:     "bg-sky-50 text-sky-700 ring-sky-600/20",
    emerald: "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
    amber:   "bg-amber-50 text-amber-700 ring-amber-600/20",
    rose:    "bg-rose-50 text-rose-700 ring-rose-600/20",
    violet:  "bg-violet-50 text-violet-700 ring-violet-600/20"
  }.freeze

  # "10 Oktober 2026" — nama bulan dari locale aktif (id/en).
  def agenda_date(date)
    "#{date.day} #{t('date.month_names')[date.month]} #{date.year}"
  end

  # Baris tanggal kartu agenda, empat bentuk:
  #   tenggat  → "Batas: 10 Oktober 2026"
  #   rentang  → "8–12 Oktober 2026"
  #   seharian → "12 Oktober 2026"
  #   berwaktu → "12 Oktober 2026 · 09.00"
  def agenda_date_line(item)
    starts = item.starts_at
    return "Batas: #{agenda_date(starts.to_date)}" if item.deadline
    return agenda_date_range(starts.to_date, item.ends_at.to_date) if item.multi_day?
    return agenda_date(starts.to_date) if item.all_day

    "#{agenda_date(starts.to_date)} · #{starts.strftime('%H.%M')}"
  end

  def agenda_date_range(from, to)
    if from.year == to.year && from.month == to.month
      "#{from.day}–#{agenda_date(to)}"
    elsif from.year == to.year
      "#{from.day} #{t('date.month_names')[from.month]} – #{agenda_date(to)}"
    else
      "#{agenda_date(from)} – #{agenda_date(to)}"
    end
  end

  # Hitung mundur di sudut kanan kartu. Agenda yang sudah lewat tidak pernah
  # sampai ke sini (controller menyaring dari hari ini), jadi tidak ada cabang negatif.
  def agenda_countdown(item)
    case item.days_away
    when 0 then "Hari ini"
    when 1 then "Besok"
    else "#{item.days_away} hari lagi"
    end
  end

  def agenda_kind_dot_class(kind)
    AGENDA_KIND_DOTS.fetch(kind.to_sym, "bg-slate-400")
  end

  def agenda_status_class(tone)
    AGENDA_STATUS_CLASSES.fetch(tone&.to_sym, AGENDA_STATUS_CLASSES[:slate])
  end
end
