import { Controller } from "@hotwired/stimulus"

// Saring baris daftar panjang dengan kotak pencarian (dipakai halaman
// Taksonomi Istilah). Setiap baris menyimpan teks carinya di
// data-text-filter-terms; grup yang semua barisnya tersaring ikut disembunyikan.
// Disembunyikan lewat style.display, bukan atribut `hidden`: baris memakai
// kelas `sm:grid` yang mengalahkan aturan [hidden] bawaan Tailwind.
export default class extends Controller {
  static targets = ["input", "row", "group", "empty"]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let visible = 0
    this.rowTargets.forEach((row) => {
      const match = !query || row.dataset.textFilterTerms.toLowerCase().includes(query)
      row.style.display = match ? "" : "none"
      if (match) visible++
    })
    this.groupTargets.forEach((group) => {
      const rows = group.querySelectorAll("[data-text-filter-target='row']")
      const anyVisible = Array.from(rows).some((row) => row.style.display !== "none")
      group.style.display = anyVisible ? "" : "none"
    })
    if (this.hasEmptyTarget) this.emptyTarget.hidden = visible > 0
  }
}
