import { Controller } from "@hotwired/stimulus"

// Handles mobile sidebar toggle and sidebar search filtering
export default class extends Controller {
  static targets = ["mobileSidebar", "overlay", "searchInput", "nav", "mobileSearchInput", "mobileNav"]

  connect() {
    // Clear any stale search state on reconnect
    if (this.hasSearchInputTarget) this.searchInputTarget.value = ""
    if (this.hasMobileSearchInputTarget) this.mobileSearchInputTarget.value = ""
  }

  open() {
    if (this.hasMobileSidebarTarget) {
      this.mobileSidebarTarget.classList.remove("-translate-x-full")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden")
    }
  }

  close() {
    if (this.hasMobileSidebarTarget) {
      this.mobileSidebarTarget.classList.add("-translate-x-full")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
  }

  search(event) {
    const query = event.target.value
    // Determine which nav to filter based on which input triggered the event
    const nav = event.target === this.mobileSearchInputTarget
      ? this.mobileNavTarget
      : this.navTarget

    this._filterNav(nav, query)
  }

  // Private

  _filterNav(nav, query) {
    if (!nav) return

    const normalizedQuery = query.toLowerCase().trim().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    const groups = nav.querySelectorAll(":scope > div")

    groups.forEach(group => {
      const links = group.querySelectorAll("a.group")
      let groupHasVisibleLink = false

      links.forEach(link => {
        const labelEl = link.querySelector("span.truncate") || link.querySelector("span:not(.bg-indigo-500)") || link
        const rawText = (labelEl ? labelEl.textContent : link.textContent) || ""
        const cleanLabel = rawText.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")

        if (normalizedQuery === "" || cleanLabel.includes(normalizedQuery)) {
          link.style.display = ""
          groupHasVisibleLink = true
        } else {
          link.style.display = "none"
        }
      })

      group.style.display = (normalizedQuery === "" || groupHasVisibleLink) ? "" : "none"
    })
  }
}
