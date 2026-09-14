import { Controller } from "@hotwired/stimulus"

// Baris resep dinamis + pratinjau format R/.
//
// Tujuannya belajar: mahasiswa mengisi kolom terpisah (obat, sediaan,
// kekuatan, jumlah, aturan pakai), lalu langsung melihat hasilnya tersusun
// sebagai resep yang benar — inscriptio "R/ ... No. X" dan signatura "S ...".
// Murni sisi klien; semua field tetap dalam satu <form> wizard.
export default class extends Controller {
  static targets = ["rows", "template", "preview", "empty"]

  connect() {
    this.renderPreview()
  }

  add(event) {
    event.preventDefault()
    const index = new Date().getTime()
    this.rowsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replace(/NEW_RECORD/g, index))
    this.toggleEmpty()
    this.renderPreview()
  }

  // Baris baru dibuang dari DOM; baris tersimpan ditandai _destroy supaya
  // penghapusannya ikut terkirim saat form disubmit.
  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-prescription-target='row']")
    if (!row) return

    const destroyField = row.querySelector("input[name*='_destroy']")
    if (destroyField) {
      destroyField.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.toggleEmpty()
    this.renderPreview()
  }

  renderPreview() {
    if (!this.hasPreviewTarget) return

    const lines = []
    this.element.querySelectorAll("[data-prescription-target='row']").forEach((row) => {
      if (row.hidden) return

      const value = (field) => (row.querySelector(`[data-field='${field}']`)?.value || "").trim()
      const name = value("medication_name")
      if (!name) return

      const head = ["R/", name, value("dosage_form_abbr"), value("strength"), value("quantity") && `No. ${value("quantity")}`]
        .filter(Boolean)
        .join(" ")
      lines.push(head)

      const signa = value("signa")
      if (signa) lines.push(`    ${/^S\b/i.test(signa) ? signa : `S ${signa}`}`)
    })

    this.previewTarget.textContent = lines.length
      ? lines.join("\n")
      : "Pratinjau resep muncul di sini setelah nama obat diisi."
  }

  toggleEmpty() {
    if (!this.hasEmptyTarget) return

    const visible = [...this.element.querySelectorAll("[data-prescription-target='row']")].some((row) => !row.hidden)
    this.emptyTarget.hidden = visible
  }
}
