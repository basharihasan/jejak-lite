import { Controller } from "@hotwired/stimulus"

// Jam di sapaan Beranda. Server sudah mencetak waktu awal (WIB), controller ini
// hanya menjaganya tetap berjalan selama halaman terbuka — zona waktunya tetap
// Asia/Jakarta, sama dengan config.time_zone aplikasi, bukan zona peramban.
export default class extends Controller {
  static targets = ["time"]

  connect() {
    this.formatter = new Intl.DateTimeFormat("id-ID", {
      hour: "2-digit", minute: "2-digit", hour12: false, timeZone: "Asia/Jakarta"
    })
    this.tick()
    this.timer = setInterval(() => this.tick(), 15000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    this.timeTarget.textContent = this.formatter.format(new Date()).replace(".", ":")
  }
}
