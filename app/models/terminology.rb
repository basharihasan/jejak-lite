# frozen_string_literal: true

# Daftar label yang boleh diganti admin lewat Konfigurasi → Taksonomi Istilah
# (padanan /admin/terminology jejak.pro). Sumbernya berkas locale bawaan,
# bukan daftar ketik tangan — menu baru di chrome.id.yml otomatis ikut bisa
# diganti tanpa menyentuh berkas ini.
#
#   nav.*   label menu sidebar & bilah bawah. Punya terjemahan English sendiri,
#           jadi penggantian hanya berlaku saat antarmuka Bahasa Indonesia.
#   terms.* istilah di halaman Logbook Kegiatan. Halaman isi masih berbahasa
#           Indonesia di kedua pilihan bahasa, jadi penggantian berlaku selalu.
module Terminology
  Entry = Data.define(:key, :default_value, :section)

  SECTIONS = {
    "menu_groups" => "Judul Grup Sidebar",
    "menu" => "Menu Sidebar",
    "mobile" => "Bilah Navigasi Bawah (Ponsel)",
    "terms" => "Istilah Logbook Kegiatan"
  }.freeze

  NAMESPACES = %w[nav terms].freeze

  module_function

  def entries
    NAMESPACES.flat_map do |namespace|
      flatten(namespace, I18n.t(namespace, locale: I18n.default_locale)).map do |key, value|
        Entry.new(key: key, default_value: value, section: section_for(key))
      end
    end
  end

  def keys
    entries.map(&:key)
  end

  def default_for(key)
    I18n.t(key, locale: I18n.default_locale, default: key.to_s)
  end

  # Penggantian label menu hanya untuk bahasa bawaan; istilah halaman isi
  # berlaku di semua bahasa (lihat komentar modul).
  def applies_to_locale?(key, locale = I18n.locale)
    !key.to_s.start_with?("nav.") || locale.to_s == I18n.default_locale.to_s
  end

  def section_for(key)
    case key
    when /\Anav\.groups\./ then "menu_groups"
    when /\Anav\.mobile\./ then "mobile"
    when /\Anav\./ then "menu"
    else "terms"
    end
  end

  def flatten(prefix, node)
    return [] unless node.is_a?(Hash)

    node.flat_map do |name, value|
      key = "#{prefix}.#{name}"
      value.is_a?(Hash) ? flatten(key, value) : [ [ key, value.to_s ] ]
    end
  end
end
