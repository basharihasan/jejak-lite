import { Controller } from "@hotwired/stimulus"

// Isian bertingkat Domain → Subdomain / Kategori → Bentuk Kegiatan pada form
// Logbook Kegiatan (meniru jejak.pro). Server mengirim peta pilihan lewat
// data-*-value dan sudah merender pilihan untuk nilai tersimpan; controller
// ini hanya membangun ulang pilihan saat tingkat di atasnya berganti, dan
// menyembunyikan isian yang tidak punya pilihan.
export default class extends Controller {
  static targets = ["domain", "subdomain", "subdomainField", "template", "templateField"]
  static values = { subdomains: Object, templates: Object }

  connect() {
    this.toggleFields()
  }

  domainChanged() {
    this.fill(this.subdomainTarget, this.subdomainsValue[this.domainTarget.value])
    this.subdomainChanged()
  }

  subdomainChanged() {
    this.fill(this.templateTarget, this.templatesValue[this.subdomainTarget.value])
    this.toggleFields()
  }

  fill(select, options = []) {
    const current = select.value
    select.replaceChildren(new Option(select.dataset.placeholder || "", ""))
    options.forEach(({ id, name }) => {
      const selected = String(id) === current
      select.add(new Option(name, id, selected, selected))
    })
  }

  toggleFields() {
    this.subdomainFieldTarget.hidden = this.subdomainTarget.options.length <= 1
    this.templateFieldTarget.hidden = this.templateTarget.options.length <= 1
  }
}
