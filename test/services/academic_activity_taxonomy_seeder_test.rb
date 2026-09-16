require "test_helper"

class AcademicActivityTaxonomySeederTest < ActiveSupport::TestCase
  test "mengisi taksonomi bawaan jejak.pro hanya bila belum ada domain sama sekali" do
    assert_equal 0, AcademicActivityTaxonomySeeder.call, "fixture sudah punya domain — tidak boleh ditambah"

    ActivityLog.update_all(academic_activity_domain_id: nil, academic_activity_subdomain_id: nil, academic_activity_template_id: nil)
    AcademicActivityTemplate.delete_all
    AcademicActivitySubdomain.delete_all
    AcademicActivityDomain.delete_all

    assert_equal 11, AcademicActivityTaxonomySeeder.call
    assert_equal [ "Praktek", "Belajar Mengajar", "Belajar Mandiri di Luar Jam KBM" ], AcademicActivityDomain.ordered.limit(3).pluck(:name)
    assert AcademicActivityDomain.find_by!(name: "Praktek").is_clinical?
    assert_equal 1, AcademicActivityDomain.where(is_clinical: true).count

    belajar = AcademicActivityDomain.find_by!(name: "Belajar Mengajar")
    assert_equal "Tutorial", belajar.academic_activity_subdomains.first.name, "Tutorial = subdomain langsung, seperti produksi jejak.pro"
    prestasi = AcademicActivityDomain.find_by!(name: "Prestasi Kemahasiswaan")
    assert_equal 7, prestasi.academic_activity_subdomains.count
    assert_equal 8, prestasi.academic_activity_subdomains.find_by!(name: "Kompetisi").academic_activity_templates.count

    assert_equal 0, AcademicActivityTaxonomySeeder.call, "idempoten"
  end
end
