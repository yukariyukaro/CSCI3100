import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["retryButton", "retryText", "retrySpinner"]

  onRetry() {
    if (this.hasRetryButtonTarget) this.retryButtonTarget.disabled = true
    if (this.hasRetryTextTarget) this.retryTextTarget.textContent = "Retrying..."
    if (this.hasRetrySpinnerTarget) this.retrySpinnerTarget.classList.remove("hidden")
  }
}
