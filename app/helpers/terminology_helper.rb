# frozen_string_literal: true

module TerminologyHelper
  # Seperti `t`, tapi memakai label pengganti dari Taksonomi Istilah bila admin
  # mengisinya. Tabelnya kecil dan sidebar dirender dua kali per halaman
  # (desktop + ponsel), jadi seluruh isinya dimuat sekali per render.
  def term(key, **options)
    text = t(key, **options)
    return text unless Terminology.applies_to_locale?(key)

    terminology_overrides.fetch(key.to_s, text)
  end

  private

  def terminology_overrides
    @_terminology_overrides ||= TerminologyOverride.to_h
  end
end
