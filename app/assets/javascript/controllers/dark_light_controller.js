import { Controller } from '@hotwired/stimulus';

const storageKey = 'oho-theme'



function setTheme(theme) {
  if (theme === 'auto') {
    theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }
  document.documentElement.setAttribute('data-bs-theme', theme)
}

function handleSystemModeChange(_event) {
  setTheme('auto')
}

window
  .matchMedia('(prefers-color-scheme: dark)')
  .addEventListener('change', handleSystemModeChange)

const initialTheme = localStorage.getItem(storageKey) || 'auto';
setTheme(initialTheme)


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
  }

  toggle(event) {
    this.theme = this.theme == 'dark' ? 'light' : 'dark'
    this.setTheme()
  }
}
