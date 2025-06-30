import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]
  connect() {
  }
  check(event) {
    this.submitTarget.disabled = event.target.files.length === 0
  }
}
