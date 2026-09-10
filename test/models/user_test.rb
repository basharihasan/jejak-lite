require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "full_name wajib diisi" do
    user = User.new(email: "tanpa_nama@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:full_name], "can't be blank"
  end

  test "has_role? membaca lewat asosiasi roles" do
    assert users(:budi).has_role?("dosen")
    assert_not users(:budi).has_role?("mahasiswa")
  end

  test "switch_active_role! menolak peran yang tidak dimiliki" do
    user = users(:budi)
    assert_not user.switch_active_role!("mahasiswa")
    assert_equal roles(:dosen), user.active_role
  end

  test "switch_active_role! berhasil untuk peran yang dimiliki" do
    user = users(:budi)
    user.roles << roles(:admin)

    assert user.switch_active_role!("admin")
    assert_equal roles(:admin), user.reload.active_role
  end
end
