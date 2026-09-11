import { Controller } from "@hotwired/stimulus"

// Chart.js sudah dimuat global lewat CDN di layout (dipakai Chartkick),
// tapi Chartkick sendiri tidak punya tipe radar — jadi controller kecil ini
// memanggil window.Chart langsung. Dipakai di show DOPS/Mini-CEX, Dashboard,
// dan Kurikulum untuk memetakan skor per dimensi/kompetensi.
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    labels: Array,
    datasets: Array,
    max: { type: Number, default: 9 }
  }

  connect() {
    if (typeof window.Chart === "undefined") return

    this.chart = new window.Chart(this.canvasTarget, {
      type: "radar",
      data: {
        labels: this.labelsValue,
        datasets: this.datasetsValue.map((dataset) => ({
          fill: true,
          borderWidth: 2,
          pointRadius: 3,
          ...dataset
        }))
      },
      options: {
        responsive: true,
        scales: {
          r: {
            min: 0,
            max: this.maxValue,
            ticks: { stepSize: this.maxValue / 3 }
          }
        },
        plugins: {
          legend: { display: this.datasetsValue.length > 1 }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
