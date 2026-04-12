import { Controller } from "@hotwired/stimulus"

// Manages the lifecycle of a single flash message element.
// - Connects: starts an auto-close timer for non-error message types.
// - close(): fades the element out then removes it from the DOM.
// - disconnect(): clears the timer to prevent memory leaks during Turbo navigation.
export default class extends Controller {
  static values = {
    autoClose: { type: Boolean, default: true },
    duration:  { type: Number,  default: 5000 }
  }

  connect () {
    if (this.autoCloseValue) {
      this.timeout = setTimeout(() => this.close(), this.durationValue)
    }
  }

  close () {
    clearTimeout(this.timeout)
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect () {
    clearTimeout(this.timeout)
  }
}
