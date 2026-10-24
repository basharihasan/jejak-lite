# frozen_string_literal: true

# Versi PDF Panduan Pengguna (app/views/panduan/panduan.pdf) — dibangkitkan
# dari panduan.md yang sama dengan halaman /panduan, memakai gaya halaman itu,
# lalu dicetak Chrome/Edge headless. Jalankan ulang setiap panduan.md berubah:
#
#   bin/rails panduan:pdf
#   CHROME_PATH="/path/ke/chrome" bin/rails panduan:pdf   # bila tidak terdeteksi
namespace :panduan do
  desc "Bangkitkan app/views/panduan/panduan.pdf dari panduan.md"
  task pdf: :environment do
    require "kramdown"
    require "tmpdir"

    dir = Rails.root.join("app/views/panduan")
    chrome = [ ENV["CHROME_PATH"],
               "C:/Program Files/Google/Chrome/Application/chrome.exe",
               "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
               "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
               "/usr/bin/google-chrome", "/usr/bin/chromium", "/usr/bin/chromium-browser" ].compact.find { |path| File.exist?(path) }
    abort "Chrome/Edge tidak ditemukan — setel CHROME_PATH." unless chrome

    body = Kramdown::Document.new(File.read(dir.join("panduan.md")), input: "kramdown").to_html
    # Gaya markdown & diagram diambil dari halaman /panduan supaya keduanya tak berbeda.
    style = File.read(dir.join("index.html.erb"))[%r{<style>(.*?)</style>}m, 1]
    updated = I18n.l(Date.current, format: :long, locale: :id)

    html = <<~HTML
      <!doctype html>
      <html lang="id">
      <head>
        <meta charset="utf-8">
        <title>Panduan Pengguna JEJAK Essential</title>
        <style>
          #{style}
          @page { size: A4; margin: 16mm 14mm 18mm; @bottom-right { content: "Halaman " counter(page); font: 9px sans-serif; color: #6b7280; } }
          body { margin: 0; font-family: Inter, "Segoe UI", ui-sans-serif, system-ui, sans-serif; font-size: 10.5pt; }
          .pdf-meta { margin: 0 0 1.25rem; font-size: 9pt; color: #6b7280; }
          .markdown-body table { display: table; }
          .markdown-body h2 { break-after: avoid; }
          .markdown-body h3, .markdown-body h4 { break-after: avoid; }
          .markdown-body tr, .markdown-body svg.dg, .markdown-body blockquote { break-inside: avoid; }
          .markdown-body h2#daftar-isi + ul { columns: 2; }
        </style>
      </head>
      <body>
        <div class="markdown-body">
          <p class="pdf-meta">Versi PDF dari halaman Panduan Pengguna (/panduan) · diperbarui #{updated}</p>
          #{body}
        </div>
      </body>
      </html>
    HTML

    Dir.mktmpdir do |tmp|
      source = File.join(tmp, "panduan.html")
      File.write(source, html)
      output = dir.join("panduan.pdf").to_s
      ok = system(chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--user-data-dir=#{tmp}/profile",
                  "--print-to-pdf=#{output}", "file:///#{source.tr('\\', '/')}", exception: false)
      abort "Gagal mencetak PDF." unless ok && File.exist?(output)
      puts "Tertulis #{output} (#{(File.size(output) / 1024.0).round} KB)"
    end
  end
end
