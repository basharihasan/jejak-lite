import { Controller } from "@hotwired/stimulus"

// Notification dropdown with animated transitions.
// Usage:
//   <div data-controller="notification-dropdown">
//     <button data-action="click->notification-dropdown#toggle">🔔</button>
//     <div data-notification-dropdown-target="menu" class="hidden scale-95 opacity-0 ...">
//       ...
//     </div>
//   </div>
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.outsideClickHandler = (event) => {
      if (!this.element.contains(event.target)) {
        this.close()
      }
    }
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    // Trigger reflow then animate in
    requestAnimationFrame(() => {
      this.menuTarget.classList.remove("scale-95", "opacity-0")
      this.menuTarget.classList.add("scale-100", "opacity-100")
    })
  }

  close() {
    this.menuTarget.classList.remove("scale-100", "opacity-100")
    this.menuTarget.classList.add("scale-95", "opacity-0")
    setTimeout(() => {
      this.menuTarget.classList.add("hidden")
    }, 150)
  }
}
