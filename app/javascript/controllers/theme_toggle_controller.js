import { Controller } from "@hotwired/stimulus"

// One-click theme cycle button in the topbar: Terang → Gelap → Ikuti Sistem.
// Applies instantly client-side, then persists silently in the background
// so the choice follows the user to their other devices/sessions.
const ORDER = ["light", "dark", "system"]

export default class extends Controller {
  cycle() {
    const root = document.documentElement
    const current = root.dataset.themePreference || "system"
    const next = ORDER[(ORDER.indexOf(current) + 1) % ORDER.length]

    window.applyAhsTheme(next)
    this.persist(next)
  }

  persist(theme) {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

    fetch(this.element.dataset.url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      body: new URLSearchParams({ "user[theme_preference]": theme })
    }).catch(() => {})
  }
}
