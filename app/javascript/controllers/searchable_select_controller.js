import { Controller } from "@hotwired/stimulus"

// Ubah <select> nama yang panjang (mahasiswa, dosen, preseptor, penguji)
// jadi kotak yang bisa diketik untuk mencari. <select> asli tetap ada —
// cuma disembunyikan — dan tetap jadi sumber nilai yang dikirim form, jadi
// controller Rails, validasi server, dan event `change` tidak berubah.
// Pasang langsung di elemen select-nya:
//   f.collection_select :student_id, @students, :id, :full_name, { include_blank: "Pilih..." },
//     class: cls, data: { controller: "searchable-select" }
// Pencarian tidak peka huruf besar/kecil maupun aksen, dan tiap kata
// dicocokkan terpisah: "sari dew" menemukan "Dewi Sari".
const MAX_RESULTS = 100
const CHEVRON = "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 20' fill='%239ca3af'%3E%3Cpath fill-rule='evenodd' d='M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z' clip-rule='evenodd'/%3E%3C/svg%3E\")"

let counter = 0

const normalize = (text) => text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().trim()

export default class extends Controller {
  static values = { placeholder: { type: String, default: "Ketik nama untuk mencari…" } }

  connect() {
    const select = this.element
    // Sisa dari snapshot Turbo lama (bila ada) — bangun ulang dari nol.
    if (select.nextElementSibling?.hasAttribute("data-searchable-select-input")) select.nextElementSibling.remove()

    this.listId = `searchable-select-${++counter}`
    this.selectId = select.id
    this.required = select.required
    this.selectDisplay = select.style.display

    const input = document.createElement("input")
    input.type = "text"
    input.setAttribute("data-searchable-select-input", "")
    input.setAttribute("role", "combobox")
    input.setAttribute("aria-autocomplete", "list")
    input.setAttribute("aria-expanded", "false")
    input.setAttribute("aria-controls", this.listId)
    input.autocomplete = "off"
    input.spellcheck = false
    input.className = select.className
    input.placeholder = this.placeholderValue
    Object.assign(input.style, {
      backgroundImage: CHEVRON, backgroundRepeat: "no-repeat",
      backgroundPosition: "right 0.6rem center", backgroundSize: "1.1rem", paddingRight: "2.25rem"
    })
    // Select tanpa kelas lebar (mis. di baris tabel) mengikuti lebar aslinya.
    if (!/(^|\s)w-/.test(select.className)) input.style.width = select.offsetWidth ? `${select.offsetWidth + 24}px` : "14rem"

    // <label for> menunjuk id select — pindahkan ke kotak ketik supaya klik
    // label memfokuskannya dan pembaca layar membacakan labelnya.
    if (this.selectId) { input.id = this.selectId; select.removeAttribute("id") }
    // Select tersembunyi yang `required` tidak bisa difokuskan browser saat
    // validasi (form gagal kirim tanpa pesan) — validasinya dipindah ke kotak ketik.
    select.required = false
    select.style.display = "none"
    select.after(input)
    this.input = input

    // Teks pilihan lama diblok saat fokus, jadi ketikan pertama langsung
    // menggantinya. Diulang di klik pertama: mouseup membatalkan blok dari focus.
    this.onFocus = () => { this.selectOnClick = true; this.open(); this.input.select() }
    this.onClick = () => {
      if (this.selectOnClick && !this.dirty) this.input.select()
      this.selectOnClick = false
      if (!this.isOpen) this.open()
    }
    this.onInput = () => { this.dirty = true; this.open() }
    this.onKeydown = (event) => this.keydown(event)
    this.onBlur = () => { this.selectOnClick = false; this.commit() }
    this.onSelectChange = () => this.sync()
    this.onReset = () => setTimeout(() => this.sync())
    this.onReposition = (event) => { if (event?.target !== this.list) this.position() }
    this.teardown = this.teardown.bind(this)

    input.addEventListener("focus", this.onFocus)
    input.addEventListener("click", this.onClick)
    input.addEventListener("input", this.onInput)
    input.addEventListener("keydown", this.onKeydown)
    input.addEventListener("blur", this.onBlur)
    select.addEventListener("change", this.onSelectChange)
    select.form?.addEventListener("reset", this.onReset)
    document.addEventListener("turbo:before-cache", this.teardown)
    // Opsi bisa diganti skrip lain — label & status nonaktif ikut diperbarui.
    this.observer = new MutationObserver(() => this.sync())
    this.observer.observe(select, { childList: true, subtree: true, attributes: true, attributeFilter: [ "disabled" ] })

    this.sync()
  }

  disconnect() {
    this.teardown()
  }

  // Kembalikan <select> asli apa adanya: dipanggil saat disconnect dan sebelum
  // Turbo menyimpan snapshot, supaya halaman dari cache tidak berisi dua kotak.
  teardown() {
    if (!this.input) return
    const select = this.element
    this.close()
    this.observer.disconnect()
    select.removeEventListener("change", this.onSelectChange)
    select.form?.removeEventListener("reset", this.onReset)
    document.removeEventListener("turbo:before-cache", this.teardown)
    this.input.remove()
    this.input = null
    if (this.selectId) select.id = this.selectId
    select.required = this.required
    select.style.display = this.selectDisplay
  }

  get selectedOption() {
    return this.element.selectedOptions[0]
  }

  get blankOption() {
    return Array.from(this.element.options).find((option) => option.value === "")
  }

  // Tampilkan label pilihan saat ini (bukan teks placeholder "Pilih..." milik opsi kosong).
  sync() {
    if (!this.input) return
    const option = this.selectedOption
    this.input.value = option && option.value !== "" ? option.text : ""
    this.input.disabled = this.element.disabled
    this.dirty = false
    this.updateValidity()
    if (this.isOpen) this.render()
  }

  updateValidity() {
    if (!this.required) return
    this.input.setCustomValidity(this.element.value ? "" : "Pilih salah satu dari daftar.")
  }

  open() {
    if (this.element.disabled) return
    if (!this.isOpen) {
      this.list = document.createElement("ul")
      this.list.id = this.listId
      this.list.setAttribute("role", "listbox")
      this.list.className = "fixed z-50 max-h-64 overflow-y-auto rounded-xl bg-white py-1 text-sm shadow-lg ring-1 ring-gray-200"
      // Tahan fokus di kotak ketik supaya klik opsi tidak memicu blur dulu.
      this.list.addEventListener("mousedown", (event) => event.preventDefault())
      this.list.addEventListener("click", (event) => {
        const item = event.target.closest("[role='option']")
        if (item && item.getAttribute("aria-disabled") !== "true") this.choose(this.results[Number(item.dataset.index)])
      })
      document.body.appendChild(this.list)
      this.input.setAttribute("aria-expanded", "true")
      window.addEventListener("scroll", this.onReposition, true)
      window.addEventListener("resize", this.onReposition)
    }
    this.render()
  }

  close() {
    if (!this.isOpen) return
    window.removeEventListener("scroll", this.onReposition, true)
    window.removeEventListener("resize", this.onReposition)
    this.list.remove()
    this.list = null
    this.input.setAttribute("aria-expanded", "false")
    this.input.removeAttribute("aria-activedescendant")
  }

  get isOpen() {
    return Boolean(this.list)
  }

  // Opsi yang cocok, diurutkan: awal nama cocok > awal salah satu kata cocok > lainnya.
  // Sebelum pengguna mengetik, semua opsi ditampilkan.
  filter() {
    const options = Array.from(this.element.options).filter((option) => option.value !== "")
    const query = this.dirty ? normalize(this.input.value) : ""
    if (!query) return options
    const tokens = query.split(/\s+/)
    return options
      .map((option) => ({ option, label: normalize(option.text) }))
      .filter(({ label }) => tokens.every((token) => label.includes(token)))
      .map(({ option, label }) => {
        const rank = label.startsWith(query) ? 0 : label.split(/[\s.,'-]+/).some((word) => word.startsWith(tokens[0])) ? 1 : 2
        return { option, rank }
      })
      .sort((a, b) => a.rank - b.rank)
      .map(({ option }) => option)
  }

  render() {
    const matches = this.filter()
    this.results = matches.slice(0, MAX_RESULTS)
    // Opsi kosong hanya muncul sebagai "Kosongkan" saat ada pilihan yang bisa dihapus.
    if (this.blankOption && !this.required && this.element.value !== "" && !this.dirty) this.results.unshift(this.blankOption)

    this.list.replaceChildren()
    this.results.forEach((option, index) => {
      const item = document.createElement("li")
      item.id = `${this.listId}-${index}`
      item.dataset.index = index
      item.setAttribute("role", "option")
      item.setAttribute("aria-selected", String(option.selected && option.value !== ""))
      item.className = "cursor-pointer px-3.5 py-2 text-gray-800"
      if (option.value === "") {
        item.textContent = "— Kosongkan pilihan —"
        item.classList.add("text-gray-500", "italic")
      } else {
        item.textContent = option.text
        if (option.selected) item.classList.add("font-semibold", "text-indigo-700")
      }
      if (option.disabled) {
        item.setAttribute("aria-disabled", "true")
        item.classList.replace("cursor-pointer", "cursor-not-allowed")
        item.classList.add("opacity-50")
      }
      this.list.appendChild(item)
    })

    if (this.results.length === 0) {
      this.addNote(this.dirty ? "Tidak ada yang cocok dengan pencarian." : "Belum ada pilihan.")
    } else if (matches.length > MAX_RESULTS) {
      this.addNote(`Menampilkan ${MAX_RESULTS} dari ${matches.length} — ketik untuk mempersempit.`)
    }

    const selectedIndex = this.results.findIndex((option) => option.selected && option.value !== "")
    this.highlight(this.dirty || selectedIndex < 0 ? this.results.findIndex((option) => option.value !== "") : selectedIndex)
    this.position()
  }

  addNote(text) {
    const note = document.createElement("li")
    note.className = "px-3.5 py-2 text-xs text-gray-400"
    note.textContent = text
    this.list.appendChild(note)
  }

  highlight(index) {
    this.activeIndex = index
    this.list.querySelectorAll("[role='option']").forEach((item, i) => item.classList.toggle("bg-indigo-50", i === index))
    const active = index >= 0 ? this.list.querySelector(`#${this.listId}-${index}`) : null
    if (active) {
      this.input.setAttribute("aria-activedescendant", active.id)
      active.scrollIntoView({ block: "nearest" })
    } else {
      this.input.removeAttribute("aria-activedescendant")
    }
  }

  move(step) {
    if (!this.results.length) return
    this.highlight(Math.min(Math.max(this.activeIndex + step, 0), this.results.length - 1))
  }

  // Daftar diletakkan `fixed` di <body> agar tidak terpotong kartu/tabel yang
  // overflow-nya tersembunyi; dibalik ke atas bila ruang di bawah sempit.
  position() {
    if (!this.isOpen) return
    const rect = this.input.getBoundingClientRect()
    const width = Math.max(rect.width, 224)
    const below = window.innerHeight - rect.bottom
    const openUp = below < 200 && rect.top > below
    Object.assign(this.list.style, {
      left: `${Math.max(8, Math.min(rect.left, window.innerWidth - width - 8))}px`,
      width: `${width}px`,
      top: openUp ? "" : `${rect.bottom + 4}px`,
      bottom: openUp ? `${window.innerHeight - rect.top + 4}px` : "",
      maxHeight: `${Math.max(120, Math.min(256, (openUp ? rect.top : below) - 12))}px`
    })
  }

  keydown(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.isOpen ? this.move(1) : this.open()
        break
      case "ArrowUp":
        event.preventDefault()
        if (this.isOpen) this.move(-1)
        break
      case "Enter":
        if (!this.isOpen) { this.commit(); break }
        // Jangan kirim form saat Enter dipakai untuk memilih nama.
        event.preventDefault()
        if (this.results[this.activeIndex] && !this.results[this.activeIndex].disabled) this.choose(this.results[this.activeIndex])
        break
      case "Escape":
        if (!this.isOpen) break
        event.preventDefault()
        this.close()
        this.sync()
        break
    }
  }

  choose(option) {
    const changed = this.element.value !== option.value
    this.element.value = option.value
    if (changed) {
      this.element.dispatchEvent(new Event("input", { bubbles: true }))
      this.element.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.sync()
    this.close()
  }

  // Saat kotak ditinggalkan: teks yang persis sama dengan satu nama dipilih,
  // teks kosong menghapus pilihan, selain itu kembali ke pilihan sebelumnya.
  commit() {
    if (!this.input) return
    if (this.dirty) {
      const query = normalize(this.input.value)
      const exact = Array.from(this.element.options).find((option) => option.value !== "" && !option.disabled && normalize(option.text) === query)
      if (exact) return this.choose(exact)
      if (!query && this.blankOption) return this.choose(this.blankOption)
    }
    this.sync()
    this.close()
  }
}
