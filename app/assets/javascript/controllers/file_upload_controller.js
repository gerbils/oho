import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]
  connect() {
    console.log('hello_controller.js: ', this.element)
  }
  check(event) {
    console.log('check: ', event)
    this.submitTarget.disabled = event.target.files.length === 0
  }
}
