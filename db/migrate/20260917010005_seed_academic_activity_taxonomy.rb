# Isi taksonomi bawaan untuk instalasi yang sudah berjalan (instalasi baru
# mendapatkannya dari db:seed, karena db:prepare memuat schema.rb dan tidak
# menjalankan migrasi ini).
#
# Kegiatan lama hanya ditautkan bila teks bebas `activity_type`-nya SAMA
# PERSIS (abaikan huruf besar/spasi) dengan satu subdomain di domain yang
# sejalan dengan kategori lamanya (klinis → domain klinis). Selebihnya
# dibiarkan tanpa domain: menebak "Non-Klinis" sebagai domain tertentu akan
# menghasilkan data yang tampak benar tapi salah.
class SeedAcademicActivityTaxonomy < ActiveRecord::Migration[8.1]
  def up
    [ AcademicActivityDomain, AcademicActivitySubdomain, AcademicActivityTemplate, ActivityLog ].each(&:reset_column_information)
    AcademicActivityTaxonomySeeder.call

    normalize = ->(text) { text.to_s.downcase.squish }
    subdomains = AcademicActivitySubdomain.includes(:academic_activity_domain).to_a
    ActivityLog.where(academic_activity_domain_id: nil).where.not(activity_type: [ nil, "" ]).find_each do |log|
      clinical = log.category == "klinis"
      matches = subdomains.select do |subdomain|
        subdomain.academic_activity_domain.is_clinical == clinical && normalize.call(subdomain.name) == normalize.call(log.activity_type)
      end
      next unless matches.one?

      log.update_columns(academic_activity_subdomain_id: matches.first.id,
                         academic_activity_domain_id: matches.first.academic_activity_domain_id)
    end
  end

  def down
    # Data taksonomi ikut hilang saat tabelnya di-rollback migrasi sebelumnya.
  end
end
