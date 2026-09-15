require "test_helper"

# Paket Dasar M02: "Kalender kegiatan berpenanda verifikasi" — Logbook
# Kegiatan sebelumnya tanpa mekanisme verifikasi sama sekali.
class ActivityLogVerificationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @log = ActivityLog.create!(user: users(:siti), title: "Jaga malam IGD", category: "klinis", activity_date: Date.current)
  end

  test "pengajar memverifikasi kegiatan mahasiswa; mahasiswa diberi tahu" do
    sign_in users(:budi)

    get activity_log_path(@log)
    assert_match "Verifikasi", response.body
    assert_match "Menunggu Verifikasi", response.body

    patch verify_activity_log_path(@log)

    assert_redirected_to activity_log_path(@log)
    assert @log.reload.verified?
    assert_equal users(:budi), @log.verified_by
    assert Notification.where(recipient: users(:siti), title: "Kegiatan terverifikasi").exists?

    sign_in users(:siti)
    get activity_log_path(@log)
    assert_match "✓ Terverifikasi", response.body
    assert_match "Diverifikasi oleh Budi Dosen", response.body
  end

  test "mahasiswa tidak bisa memverifikasi kegiatannya sendiri" do
    sign_in users(:siti)
    patch verify_activity_log_path(@log)
    assert_not @log.reload.verified?
  end

  test "mahasiswa lain tidak bisa melihat kegiatan orang lain" do
    other = User.create!(full_name: "Mahasiswa Lain", email: "lain@example.com", password: "password123", confirmed_at: Time.current)
    other.roles << roles(:mahasiswa)
    sign_in other

    get activity_log_path(@log)
    assert_redirected_to root_path
    assert_equal "Anda tidak memiliki akses untuk melakukan itu.", flash[:alert]
  end

  test "kegiatan yang sudah terverifikasi tidak bisa diverifikasi ulang" do
    @log.verify!(by: users(:budi))
    sign_in users(:wati)
    patch verify_activity_log_path(@log)
    assert_equal users(:budi), @log.reload.verified_by
  end

  test "tab Perlu Diverifikasi menampilkan kegiatan lintas mahasiswa yang belum terverifikasi" do
    verified_log = ActivityLog.create!(user: users(:siti), title: "Kuliah pakar", category: "non_klinis",
                                        activity_date: Date.current, verified_at: 1.day.ago, verified_by: users(:budi))
    sign_in users(:budi)

    get activity_logs_path(scope: "to_verify")

    assert_response :success
    assert_match "Jaga malam IGD", response.body
    assert_match "Siti Mahasiswa", response.body
    assert_no_match "Kuliah pakar", response.body
    verified_log.destroy
  end

  test "mahasiswa tidak melihat tab Perlu Diverifikasi dan scope jatuh ke Punya Saya" do
    other_log = ActivityLog.create!(user: users(:wati), title: "Kegiatan orang lain", category: "non_klinis", activity_date: Date.current)
    sign_in users(:siti)
    get activity_logs_path
    assert_no_match "Perlu Diverifikasi", response.body

    get activity_logs_path(scope: "to_verify")
    assert_response :success
    assert_match "Jaga malam IGD", response.body   # miliknya sendiri, tetap tampil
    assert_no_match "Kegiatan orang lain", response.body # bukan pengajar, tak lihat milik orang lain
    other_log.destroy
  end

  test "kalender menandai hari dengan warna berbeda untuk kegiatan belum terverifikasi vs sudah" do
    sign_in users(:siti)
    get activity_logs_calendar_path
    assert_match "bg-indigo-500", response.body

    @log.verify!(by: users(:budi))
    get activity_logs_calendar_path
    assert_match "bg-emerald-500", response.body
  end
end
