import { Controller } from "@hotwired/stimulus"

// Manages light/dark theme toggle.
// Persists preference in localStorage and applies [data-theme] on <html>.
export default class extends Controller {
  connect() {
    this._syncVisual()
  }

  toggle() {
    const html = document.documentElement
    const isDark = html.getAttribute("data-theme") === "dark"
    const next = isDark ? "light" : "dark"
    html.setAttribute("data-theme", next)
    localStorage.setItem("theme", next)
    this._syncVisual()
  }

  _syncVisual() {
    const isDark = document.documentElement.getAttribute("data-theme") === "dark"
    this.element.setAttribute("data-dark", isDark ? "true" : "false")
  }
}
