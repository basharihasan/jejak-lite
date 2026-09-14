import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    if (this.openValue) {
      this.show()
    } else {
      this.hide()
    }
  }

  toggle() {
    this.openValue = !this.openValue
    this.openValue ? this.show() : this.hide()
  }

  show() {
    this.contentTarget.classList.remove("hidden")
    if (this.hasIconTarget) {
      this.iconTarget.classList.add("rotate-180")
    }
  }

  hide() {
    this.contentTarget.classList.add("hidden")
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-180")
    }
  }
}
