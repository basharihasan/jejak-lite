import { Controller } from "@hotwired/stimulus"

// Tombol "Aktifkan Notifikasi Push" di halaman Notifikasi. Meniru pola
// resmi Rails: registrasi service worker root (/service-worker) supaya
// scope-nya mencakup seluruh situs, lalu subscribe PushManager dengan
// kunci VAPID publik dan kirim langganannya ke server.
export default class extends Controller {
  static targets = ["button", "status"]

  connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.setStatus("Browser ini tidak mendukung notifikasi push.")
      this.buttonTarget.disabled = true
      return
    }

    this.refreshState()
  }

  async refreshState() {
    const registration = await navigator.serviceWorker.ready.catch(() => null)
    const subscription = registration ? await registration.pushManager.getSubscription() : null

    if (subscription) {
      this.buttonTarget.textContent = "Matikan Notifikasi Push"
      this.buttonTarget.dataset.subscribed = "true"
      this.setStatus("Notifikasi push aktif di perangkat ini.")
    } else {
      this.buttonTarget.textContent = "Aktifkan Notifikasi Push"
      this.buttonTarget.dataset.subscribed = "false"
      this.setStatus("")
    }
  }

  async toggle() {
    this.buttonTarget.disabled = true

    try {
      if (this.buttonTarget.dataset.subscribed === "true") {
        await this.unsubscribe()
      } else {
        await this.subscribe()
      }
    } catch (error) {
      this.setStatus(`Gagal: ${error.message}`)
    } finally {
      this.buttonTarget.disabled = false
      this.refreshState()
    }
  }

  async subscribe() {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") {
      throw new Error("izin notifikasi ditolak")
    }

    const registration = await navigator.serviceWorker.register("/service-worker")
    await navigator.serviceWorker.ready

    const { publicKey } = await fetch("/vapid_public_key").then((r) => r.json())
    if (!publicKey) {
      throw new Error("server belum mengonfigurasi kunci VAPID")
    }

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(publicKey)
    })

    await fetch("/device_push_token", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ subscription: subscription.toJSON() })
    })
  }

  async unsubscribe() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()
    if (!subscription) return

    const endpoint = subscription.endpoint
    await subscription.unsubscribe()

    await fetch(`/device_push_token?endpoint=${encodeURIComponent(endpoint)}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    return Uint8Array.from([...rawData].map((char) => char.charCodeAt(0)))
  }
}
