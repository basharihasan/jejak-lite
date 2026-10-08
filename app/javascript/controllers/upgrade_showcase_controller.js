import { Controller } from "@hotwired/stimulus"

// Kartu "Tumbuh bersama JEJAK" di Beranda: tab fitur jejak.pro yang berganti
// sendiri (berhenti saat disorot/difokus, berhenti permanen begitu pengguna
// memilih tab), tertutup secara bawaan, dan status buka/tutup diingat per peramban.
// Menghormati prefers-reduced-motion: tanpa putar otomatis dan tanpa animasi.
export default class extends Controller {
  static targets = ["tab", "panel", "progress", "body", "chevron", "toggleLabel", "dot"]
  static classes = ["active", "inactive"]
  static values = {
    interval: { type: Number, default: 6500 },
    storageKey: { type: String, default: "jejak:upgrade-showcase:collapsed" }
  }

  connect() {
    this.index = 0
    this.autoplay = !this.reducedMotion
    this.hovering = false
    this.collapsed = this.readCollapsed()
    this.select(0, { animate: false })
    this.startTrackDot()
    this.setCollapsed(this.collapsed, { persist: false })
  }

  disconnect() {
    this.progressAnimation?.cancel()
    this.dotAnimation?.cancel()
  }

  // Aksi: klik tab
  choose(event) {
    this.autoplay = false
    this.select(event.params.index)
  }

  // Aksi: panah kiri/kanan/atas/bawah, Home, End di daftar tab
  navigate(event) {
    const last = this.tabTargets.length - 1
    const moves = { ArrowRight: this.index + 1, ArrowDown: this.index + 1, ArrowLeft: this.index - 1, ArrowUp: this.index - 1, Home: 0, End: last }
    if (!(event.key in moves)) return

    event.preventDefault()
    this.autoplay = false
    const next = (moves[event.key] + this.tabTargets.length) % this.tabTargets.length
    this.select(next)
    this.tabTargets[next].focus()
  }

  pause() {
    this.hovering = true
    this.progressAnimation?.pause()
  }

  resume() {
    this.hovering = false
    if (this.autoplay && !this.collapsed) this.progressAnimation?.play()
  }

  toggle() {
    this.setCollapsed(!this.collapsed)
  }

  select(index, { animate = true } = {}) {
    this.index = index

    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.setAttribute("aria-selected", active)
      tab.tabIndex = active ? 0 : -1
      tab.classList.remove(...(active ? this.inactiveClasses : this.activeClasses))
      tab.classList.add(...(active ? this.activeClasses : this.inactiveClasses))
    })

    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
      if (i === index && animate && !this.reducedMotion) {
        panel.animate(
          [{ opacity: 0, transform: "translateY(6px)" }, { opacity: 1, transform: "none" }],
          { duration: 260, easing: "ease-out" }
        )
      }
    })

    this.runProgress()
  }

  runProgress() {
    this.progressAnimation?.cancel()
    this.progressTargets.forEach((bar) => { bar.style.transform = "scaleX(0)" })

    const bar = this.progressTargets[this.index]
    if (!bar) return

    if (!this.autoplay) {
      bar.style.transform = "scaleX(1)"
      return
    }

    this.progressAnimation = bar.animate(
      [{ transform: "scaleX(0)" }, { transform: "scaleX(1)" }],
      { duration: this.intervalValue, easing: "linear", fill: "forwards" }
    )
    if (this.hovering || this.collapsed) this.progressAnimation.pause()
    this.progressAnimation.onfinish = () => {
      if (this.autoplay) this.select((this.index + 1) % this.tabTargets.length)
    }
  }

  startTrackDot() {
    if (!this.hasDotTarget || this.reducedMotion) return

    this.dotAnimation = this.dotTarget.animate(
      [
        { left: "0%", opacity: 0 },
        { left: "15%", opacity: 1, offset: 0.15 },
        { left: "85%", opacity: 1, offset: 0.85 },
        { left: "100%", opacity: 0 }
      ],
      { duration: 2800, iterations: Infinity, easing: "ease-in-out" }
    )
  }

  setCollapsed(collapsed, { persist = true } = {}) {
    this.collapsed = collapsed
    this.bodyTarget.hidden = collapsed
    this.element.querySelector("[aria-controls]")?.setAttribute("aria-expanded", !collapsed)
    if (this.hasChevronTarget) this.chevronTarget.classList.toggle("rotate-180", collapsed)
    if (this.hasToggleLabelTarget) this.toggleLabelTarget.textContent = collapsed ? "Tampilkan" : "Ciutkan"

    if (collapsed) {
      this.progressAnimation?.pause()
    } else if (this.autoplay && !this.hovering) {
      this.progressAnimation?.play()
    }

    if (persist) {
      try { localStorage.setItem(this.storageKeyValue, collapsed ? "1" : "0") } catch (_) {}
    }
  }

  readCollapsed() {
    // Bawaan: tertutup, agar kartu tidak mencolok. Terbuka hanya bila pengguna
    // pernah memilih "Tampilkan" di peramban ini.
    try { return localStorage.getItem(this.storageKeyValue) !== "0" } catch (_) { return true }
  }

  get reducedMotion() {
    return window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
  }
}
