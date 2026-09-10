require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "daftar akun baru memberi peran sesuai role_code, tanpa menyentuh kolom User" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          full_name: "Andi Baru",
          email: "andi.baru@example.com",
          role_code: "mahasiswa",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.order(:id).last
    assert_equal "Andi Baru", user.full_name
    assert user.has_role?("mahasiswa")
    assert_equal roles(:mahasiswa), user.active_role
  end

  # Regresi: role_code sempat ikut ke User.new lewat sign_up_params bawaan
  # Devise dan meledak sebagai ActiveModel::UnknownAttributeError karena
  # bukan kolom User — role_code murni dipakai assign_initial_role.
  test "role_code tidak diteruskan sebagai atribut User" do
    post user_registration_path, params: {
      user: {
        full_name: "Citra Baru",
        email: "citra.baru@example.com",
        role_code: "dosen",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_response :redirect
  end

  test "role_code tidak dikenal jatuh ke peran mahasiswa" do
    post user_registration_path, params: {
      user: {
        full_name: "Dedi Baru",
        email: "dedi.baru@example.com",
        role_code: "peran_tidak_ada",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    user = User.order(:id).last
    assert_equal "Dedi Baru", user.full_name
    assert user.has_role?("mahasiswa")
  end
end
