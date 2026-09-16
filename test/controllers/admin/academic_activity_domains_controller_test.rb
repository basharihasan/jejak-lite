require "test_helper"

# Konfigurasi → Domain Kegiatan Akademik: admin mengelola Domain → Subdomain
# → Bentuk Kegiatan yang dipakai form Logbook Kegiatan.
class Admin::AcademicActivityDomainsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    sign_in @admin
  end

  test "bukan admin ditolak" do
    sign_in users(:siti)
    get admin_academic_activity_domains_path
    assert_redirected_to dashboard_path

    patch toggle_active_admin_academic_activity_domain_path(academic_activity_domains(:praktek))
    assert academic_activity_domains(:praktek).reload.is_active?
  end

  test "menu tampil di Konfigurasi dan halaman menampilkan seluruh pohon beserta pemakaian" do
    get admin_academic_activity_domains_path

    assert_response :success
    assert_select "aside#sidebar a[href=?]", admin_academic_activity_domains_path, text: "Domain Kegiatan Akademik"
    assert_select "#domain-#{academic_activity_domains(:praktek).id}", text: /Jaga UGD/
    assert_select "#domain-#{academic_activity_domains(:prestasi).id}", text: /Juara-1 Perorangan/
    assert_select "#domain-#{academic_activity_domains(:belajar_mengajar).id}", text: /1 kegiatan/
    assert_match "kegiatan lama", response.body
    # Hapus hanya ditawarkan untuk yang belum dipakai.
    assert_select "form[action=?]", admin_academic_activity_domain_path(academic_activity_domains(:belajar_mengajar)), count: 0
    assert_select "form[action=?]", admin_academic_activity_domain_path(academic_activity_domains(:prestasi))
  end

  test "menambah dan menyunting domain" do
    assert_difference "AcademicActivityDomain.count", 1 do
      post admin_academic_activity_domains_path, params: {
        academic_activity_domain: { name: "Screening", color_code: "#EC4899", is_clinical: "1", is_active: "1" }
      }
    end
    domain = AcademicActivityDomain.order(:id).last
    assert_redirected_to admin_academic_activity_domains_path(anchor: "domain-#{domain.id}")
    assert_equal "#ec4899", domain.color_code
    assert domain.is_clinical?
    assert_equal 5, domain.position, "ditambahkan di urutan terakhir"

    patch admin_academic_activity_domain_path(domain), params: { academic_activity_domain: { name: "Skrining", is_clinical: "0" } }
    assert_equal "Skrining", domain.reload.name
    assert_not domain.is_clinical?
  end

  test "nama kembar dan warna tidak sah ditolak" do
    post admin_academic_activity_domains_path, params: { academic_activity_domain: { name: "praktek", color_code: "merah" } }

    assert_response :unprocessable_entity
    assert_match "sudah digunakan", response.body
    assert_match "harus berformat #RRGGBB", response.body
  end

  test "menambah subdomain dan bentuk kegiatan" do
    domain = academic_activity_domains(:belajar_mengajar)
    get new_admin_academic_activity_domain_academic_activity_subdomain_path(domain)
    assert_response :success

    assert_difference "AcademicActivitySubdomain.count", 1 do
      post admin_academic_activity_domain_academic_activity_subdomains_path(domain),
           params: { academic_activity_subdomain: { name: "Bed-site Teaching", is_active: "1" } }
    end
    subdomain = AcademicActivitySubdomain.order(:id).last
    assert_equal domain, subdomain.academic_activity_domain
    assert_equal 3, subdomain.position

    get new_admin_academic_activity_subdomain_academic_activity_template_path(subdomain)
    assert_response :success
    assert_difference "AcademicActivityTemplate.count", 1 do
      post admin_academic_activity_subdomain_academic_activity_templates_path(subdomain),
           params: { academic_activity_template: { name: "Bedside pagi", is_active: "1" } }
    end
    assert_redirected_to admin_academic_activity_domains_path(anchor: "domain-#{domain.id}")

    get edit_admin_academic_activity_template_path(AcademicActivityTemplate.order(:id).last)
    assert_response :success
    get edit_admin_academic_activity_subdomain_path(subdomain)
    assert_response :success
  end

  test "menonaktifkan subdomain menyembunyikannya dari form logbook" do
    subdomain = academic_activity_subdomains(:jaga_ugd)
    patch toggle_active_admin_academic_activity_subdomain_path(subdomain)
    assert_not subdomain.reload.is_active?
    follow_redirect!
    assert_match "dinonaktifkan", response.body

    sign_in users(:siti)
    get new_activity_log_path
    form = css_select("form[data-controller='activity-taxonomy']").first
    names = JSON.parse(form["data-activity-taxonomy-subdomains-value"])[subdomain.academic_activity_domain_id.to_s].map { |option| option["name"] }
    assert_equal [ "Poliklinik" ], names
  end

  test "menggeser urutan domain" do
    patch move_admin_academic_activity_domain_path(academic_activity_domains(:belajar_mengajar), direction: "up")

    assert_redirected_to admin_academic_activity_domains_path(anchor: "domain-#{academic_activity_domains(:belajar_mengajar).id}")
    assert_equal [ "Belajar Mengajar", "Praktek" ], AcademicActivityDomain.ordered.limit(2).pluck(:name)
  end

  test "hapus ditolak bila sudah dipakai kegiatan, berhasil bila belum" do
    assert_no_difference "AcademicActivitySubdomain.count" do
      delete admin_academic_activity_subdomain_path(academic_activity_subdomains(:tutorial))
    end
    assert_match "tidak bisa dihapus", flash[:alert]

    assert_difference "AcademicActivityTemplate.count", -1 do
      delete admin_academic_activity_template_path(academic_activity_templates(:juara_2))
    end
    assert_difference [ "AcademicActivityDomain.count", "AcademicActivitySubdomain.count" ], -1 do
      delete admin_academic_activity_domain_path(academic_activity_domains(:prestasi))
    end
  end
end
