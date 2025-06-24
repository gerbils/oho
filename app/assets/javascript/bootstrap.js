// import "jquery"
import "@popperjs/core"
import * as bootstrap from "bootstrap";

// import 'data-confirm-modal'

window.oho_bs = bootstrap;

document.addEventListener('turbo:load', () => {
  document.querySelectorAll('[data-toggle="tooltip"]').forEach(t => t.tooltip())
  document.querySelectorAll('[data-toggle="popover"]').forEach(t => t.popover())
})
