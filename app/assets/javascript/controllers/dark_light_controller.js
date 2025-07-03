import { Controller } from '@hotwired/stimulus';

const storageKey = 'oho-theme'


export default class extends Controller {
  initialize() {
    this.theme = localStorage.getItem(storageKey) || 'auto'
    this.setTheme(this.theme)
  }

  setTheme(theme) {
    if (this.theme === 'auto') {
      this.theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
    }
    document.body.setAttribute('data-bs-theme', this.theme)
    localStorage.setItem(storageKey, this.theme)
  }

  toggle(event) {
    this.theme = this.theme == 'dark' ? 'light' : 'dark'
    this.setTheme()
  }
}
