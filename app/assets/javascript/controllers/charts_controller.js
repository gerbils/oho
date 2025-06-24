import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="charts"
export default class extends Controller {
  connect() {
  }
  close(e) {
    e.preventDefault();
    const modal = document.getElementById("chart-modal");
    modal.innerHTML = "";
    modal.removeAttribute("src");
    modal.removeAttribute("complete");
  }
}
