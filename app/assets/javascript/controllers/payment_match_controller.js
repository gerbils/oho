import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="payment-match"
// Amounts are integers in 1/10000ths of a dollar, to avoid floating point sums.
export default class extends Controller {
  static targets = ["checkbox", "total", "apply"]
  static values = { target: Number }

  connect() {
    this.update()
  }

  update() {
    const total = this.checkboxTargets
      .filter((box) => box.checked)
      .reduce((sum, box) => sum + parseInt(box.dataset.amount, 10), 0)

    this.totalTarget.textContent = (total / 10000).toLocaleString("en-US", { style: "currency", currency: "USD" })
    const matches = total === this.targetValue && this.checkboxTargets.some((box) => box.checked)
    this.totalTarget.classList.toggle("text-success", matches)
    this.totalTarget.classList.toggle("text-danger", !matches)
    this.applyTarget.disabled = !matches
  }

  close(e) {
    e.preventDefault()
    const frame = document.getElementById("modal")
    frame.innerHTML = ""
    frame.removeAttribute("src")
    frame.removeAttribute("complete")
  }
}
