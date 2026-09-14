require "test_helper"

# Latihan menulis resep pada Logbook Kasus Klinis: baris resep terstruktur,
# format R/ pada halaman kasus, master obat untuk datalist.
class PrescriptionPracticeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @case = clinical_cases(:draft_case_siti)
    @paracetamol = MedicationDefinition.create!(name: "Parasetamol", strength: "500 mg", dosage_form: "Tablet",
                                                category: "Analgesik-Antipiretik", usual_dosage: "3-4 x 500 mg")
  end

  test "form kasus menyediakan baris resep, datalist obat, dan pratinjau" do
    sign_in users(:siti)
    get new_clinical_case_path

    assert_response :success
    assert_match "latihan menulis resep", response.body
    assert_select "[data-controller=prescription]"
    assert_select "template[data-prescription-target=template]"
    assert_select "datalist#medication-definitions option[value=?]", "Parasetamol"
    assert_select "[data-prescription-target=preview]"
  end

  test "mahasiswa menulis resep; tersimpan terstruktur dan tampil dalam format R/" do
    sign_in users(:siti)

    assert_difference "PrescriptionItem.count", 2 do
      patch clinical_case_path(@case), params: { clinical_case: {
        prescription_items_attributes: {
          "0" => { medication_name: "Parasetamol", dosage_form: "Tablet", strength: "500 mg", quantity: "X",
                   signa: "3 dd tab I p.c.", route: "Oral" },
          "1" => { medication_name: "Amoksisilin", dosage_form: "Kapsul", strength: "500 mg", quantity: "XV",
                   signa: "S 3 dd caps I", notes: "Habiskan" }
        }
      } }
    end
    assert_redirected_to clinical_case_path(@case)

    items = @case.reload.prescription_items.ordered
    assert_equal %w[Parasetamol Amoksisilin], items.map(&:medication_name)
    assert_equal "R/ Parasetamol tab 500 mg No. X", items.first.prescription_line
    assert_equal "S 3 dd tab I p.c.", items.first.signa_line
    # Awalan "S" yang sudah ditulis mahasiswa tidak digandakan.
    assert_equal "S 3 dd caps I", items.second.signa_line

    get clinical_case_path(@case)
    assert_match "R/ Parasetamol tab 500 mg No. X", response.body
    assert_match "S 3 dd tab I p.c.", response.body
    assert_match "Habiskan", response.body
  end

  test "baris yang benar-benar kosong dibuang diam-diam" do
    sign_in users(:siti)

    assert_difference "PrescriptionItem.count", 1 do
      patch clinical_case_path(@case), params: { clinical_case: {
        prescription_items_attributes: {
          "0" => { medication_name: "Parasetamol", signa: "3 dd tab I" },
          "1" => { medication_name: "", strength: "", dosage_form: "", quantity: "", signa: "", route: "", notes: "" }
        }
      } }
    end
    assert_redirected_to clinical_case_path(@case)
  end

  test "baris terisi sebagian tanpa nama obat ditahan dan dilaporkan" do
    sign_in users(:siti)

    assert_no_difference "PrescriptionItem.count" do
      patch clinical_case_path(@case), params: { clinical_case: {
        prescription_items_attributes: { "0" => { medication_name: "", signa: "3 dd tab I", quantity: "X" } }
      } }
    end
    assert_response :unprocessable_entity
    assert_match "harus diisi pada baris resep", response.body
  end

  test "baris resep dapat dihapus lewat _destroy" do
    item = @case.prescription_items.create!(medication_name: "Parasetamol", signa: "3 dd tab I")
    sign_in users(:siti)

    assert_difference "PrescriptionItem.count", -1 do
      patch clinical_case_path(@case), params: { clinical_case: {
        prescription_items_attributes: { "0" => { id: item.id, medication_name: "Parasetamol", _destroy: "1" } }
      } }
    end
  end

  test "kasus tanpa resep tidak menampilkan blok resep" do
    sign_in users(:siti)
    get clinical_case_path(@case)

    assert_response :success
    assert_select "pre", text: /R\//, count: 0
  end

  test "preseptor melihat resep mahasiswa saat meninjau kasus" do
    @case.prescription_items.create!(medication_name: "Amoksisilin", dosage_form: "Kapsul", strength: "500 mg",
                                     quantity: "XV", signa: "3 dd caps I")
    @case.update!(status: "submitted")
    sign_in users(:budi)

    get clinical_case_path(@case)
    assert_response :success
    assert_match "R/ Amoksisilin kaps 500 mg No. XV", response.body
  end

  test "resep ikut terhapus bila kasusnya dihapus" do
    @case.prescription_items.create!(medication_name: "Parasetamol")
    sign_in users(:siti)

    assert_difference "PrescriptionItem.count", -1 do
      delete clinical_case_path(@case)
    end
  end

  # ── Master obat ──
  test "admin mengelola master obat dan mengimpor CSV" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    get admin_medication_definitions_path
    assert_response :success
    assert_match "Parasetamol", response.body

    assert_difference "MedicationDefinition.count", 1 do
      post admin_medication_definitions_path, params: { medication_definition: {
        name: "Ibuprofen", strength: "400 mg", dosage_form: "Tablet", category: "AINS", active: "1"
      } }
    end

    csv = Rack::Test::UploadedFile.new(
      StringIO.new("nama,kekuatan,sediaan,kelas,dosis_lazim\nOmeprazol,20 mg,Kapsul,PPI,1 x 20 mg\nIbuprofen,400 mg,Tablet,AINS,3 x 400 mg\n"),
      "text/csv", original_filename: "obat.csv"
    )
    assert_difference "MedicationDefinition.count", 1 do
      post import_admin_medication_definitions_path, params: { file: csv }
    end
    follow_redirect!
    assert_match "1 baru, 1 diperbarui", response.body
    assert_equal "1 x 20 mg", MedicationDefinition.find_by(name: "Omeprazol").usual_dosage
  end

  test "obat dengan nama & kekuatan sama tidak boleh ganda" do
    duplicate = MedicationDefinition.new(name: "parasetamol", strength: "500 mg")
    assert_not duplicate.valid?
    assert_match "sudah ada", duplicate.errors.full_messages.to_sentence

    # Kekuatan berbeda tetap boleh — sediaan sirup vs tablet.
    assert MedicationDefinition.new(name: "Parasetamol", strength: "120 mg/5 mL").valid?
  end

  test "bukan admin ditolak mengelola master obat" do
    sign_in users(:siti)
    get admin_medication_definitions_path
    assert_redirected_to dashboard_path
  end
end
