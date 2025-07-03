import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="author-search"
export default class extends Controller {
  static targets = ["form", "input", "result"]

  connect() {
    this.timeout = null
    this.active = false
    console.log("connecting")
    const len = this.inputTarget.value.length
    this.inputTarget.setSelectionRange(len, len)
  }

  search(el) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      if (el.target.value.length > 2 || this.active) {
        this.formTarget.requestSubmit()
        this.active = true
      }
    }, 200)
  }
}
