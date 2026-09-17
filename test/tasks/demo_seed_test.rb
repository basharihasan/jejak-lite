require "test_helper"
require "rake"

class DemoSeedTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("demo:seed")
    @original_password = ENV["DEMO_PASSWORD"]
  end

  teardown { ENV["DEMO_PASSWORD"] = @original_password }

  def run_seed
    Rake::Task["demo:seed"].reenable
    capture_io { Rake::Task["demo:seed"].invoke }
  end

  test "akun demo terbentuk, terkonfirmasi, dan bisa masuk; aman diulang" do
    ENV.delete("DEMO_PASSWORD")
    run_seed
    admin = User.find_by!(email: "admin.demo@jejaklite.test")
    assert admin.valid_password?("password123")
    assert admin.active_for_authentication?

    assert_no_difference("User.count") { run_seed }
  end

  test "DEMO_PASSWORD yang diganti belakangan ikut berlaku untuk akun demo lama dan tidak dicetak" do
    ENV.delete("DEMO_PASSWORD")
    run_seed

    ENV["DEMO_PASSWORD"] = "sandi-demo-baru-42"
    out, = run_seed
    assert User.find_by!(email: "dosen.demo@jejaklite.test").valid_password?("sandi-demo-baru-42")
    assert_no_match "sandi-demo-baru-42", out
  end

  test "DEMO_PASSWORD kosong tidak menghapus sandi" do
    ENV["DEMO_PASSWORD"] = ""
    run_seed
    assert User.find_by!(email: "admin.demo@jejaklite.test").valid_password?("password123")
  end
end
