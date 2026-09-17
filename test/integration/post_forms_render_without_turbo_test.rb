require "test_helper"

# Turbo menolak jawaban POST yang berupa halaman 200 tanpa redirect
# ("Form responses must redirect to another location") — halamannya tampak
# diam. Formulir yang aksinya memang me-render hasil (alur impor
# bertahap) wajib dikirim tanpa Turbo.
class PostFormsRenderWithoutTurboTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    sign_in @admin
  end

  def assert_form_without_turbo(action)
    form = Nokogiri::HTML5(response.body).at_css("form[action='#{action}']")
    assert form, "formulir #{action} harus ada"
    assert_equal "false", form["data-turbo"], "formulir #{action} harus data-turbo=false"
  end

  test "dua langkah impor nilai dikirim tanpa Turbo" do
    event = assessment_events(:cbt_blok)
    get import_admin_assessment_event_path(event)
    assert_form_without_turbo import_preview_admin_assessment_event_path(event)

    post import_preview_admin_assessment_event_path(event),
         params: { file: Rack::Test::UploadedFile.new(StringIO.new("email,skor\nsiti@example.com,80\n"), "text/csv", original_filename: "n.csv") }
    assert_response :success
    assert_form_without_turbo import_create_admin_assessment_event_path(event)
  end

  test "impor pengguna dikirim tanpa Turbo" do
    get import_admin_users_path
    assert_form_without_turbo import_admin_users_path
  end
end
