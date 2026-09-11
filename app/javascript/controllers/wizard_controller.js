import { Controller } from "@hotwired/stimulus"

// Wizard bertahap murni sisi klien — semua field tetap ada di satu <form>
// (cuma disembunyikan pakai [hidden], bukan dihapus dari DOM), jadi submit
// akhir tetap satu POST/PATCH normal berisi semua field, tanpa perubahan di
// controller. Meniru pola wizard "Langkah X dari Y" JEJAK asli untuk form
// klinis yang panjang, tanpa perlu library form-wizard tambahan.
export default class extends Controller {
  static targets = ["step", "dot", "label", "prevButton", "nextButton", "submitButton"]
  static values = { current: { type: Number, default: 0 } }

  connect() {
    this.render()
  }

  next() {
    if (this.currentValue < this.stepTargets.length - 1) this.currentValue++
    this.render()
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  prev() {
    if (this.currentValue > 0) this.currentValue--
    this.render()
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  render() {
    const total = this.stepTargets.length

    this.stepTargets.forEach((el, i) => { el.hidden = i !== this.currentValue })
    this.dotTargets.forEach((el, i) => {
      el.classList.toggle("bg-indigo-600", i <= this.currentValue)
      el.classList.toggle("bg-gray-200", i > this.currentValue)
    })
    if (this.hasLabelTarget) this.labelTarget.textContent = `Langkah ${this.currentValue + 1} dari ${total}`
    if (this.hasPrevButtonTarget) this.prevButtonTarget.hidden = this.currentValue === 0
    if (this.hasNextButtonTarget) this.nextButtonTarget.hidden = this.currentValue === total - 1
    if (this.hasSubmitButtonTarget) this.submitButtonTarget.hidden = this.currentValue !== total - 1
  }
}
