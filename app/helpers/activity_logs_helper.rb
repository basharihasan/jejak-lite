# frozen_string_literal: true

module ActivityLogsHelper
  HEX_COLOR = /\A#\h{6}\z/

  # Peta pilihan untuk isian bertingkat form Logbook Kegiatan:
  # { "domain_id" => [{ id:, name: }] }. Hanya pilihan aktif, ditambah pilihan
  # yang sudah tersimpan di kegiatan ini (walau kini nonaktif).
  def activity_subdomain_options(domains, activity_log)
    domains.to_h do |domain|
      subdomains = domain.academic_activity_subdomains.select do |subdomain|
        subdomain.is_active? || subdomain.id == activity_log.academic_activity_subdomain_id
      end
      [ domain.id.to_s, subdomains.map { |subdomain| { id: subdomain.id, name: subdomain.name } } ]
    end
  end

  # { "subdomain_id" => [{ id:, name: }] } — lihat activity_subdomain_options.
  def activity_template_options(domains, activity_log)
    domains.flat_map(&:academic_activity_subdomains).to_h do |subdomain|
      templates = subdomain.academic_activity_templates.select do |template|
        template.is_active? || template.id == activity_log.academic_activity_template_id
      end
      [ subdomain.id.to_s, templates.map { |template| { id: template.id, name: template.name } } ]
    end
  end

  # Pil domain berwarna: titik warna + teks netral, supaya tetap terbaca di
  # mode terang maupun gelap apa pun warna yang dipilih admin.
  def activity_domain_badge(activity_log)
    tag.span(class: "inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full bg-gray-100 text-gray-700") do
      safe_join([ activity_color_dot(activity_log.domain_color), activity_log.domain_label ])
    end
  end

  def activity_color_dot(color, size: "h-2 w-2")
    tag.span(class: "#{size} rounded-full shrink-0 inline-block", style: "background-color: #{safe_activity_color(color)}")
  end

  # Warna masuk atribut style, jadi hanya format #RRGGBB yang diloloskan.
  def safe_activity_color(color)
    color.to_s.match?(HEX_COLOR) ? color : AcademicActivityDomain::DEFAULT_COLOR
  end
end
