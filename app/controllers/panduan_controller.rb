# frozen_string_literal: true

class PanduanController < ApplicationController
  before_action :authenticate_user!

  # Konten ditulis maintainer di app/views/panduan/panduan.md (bukan input
  # pengguna), jadi keluaran Kramdown aman ditandai html_safe tanpa sanitasi
  # tambahan — berbeda dari markdown yang berasal dari pengguna.
  def index
    markdown = File.read(Rails.root.join("app/views/panduan/panduan.md"))
    @content_html = Kramdown::Document.new(markdown, input: "kramdown").to_html.html_safe
  end
end
