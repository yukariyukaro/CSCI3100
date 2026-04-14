import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "question", "button", "buttonText", "spinner", "error", "loading", "serverMessage"]

  onSubmit(event) {
    const question = this.hasQuestionTarget ? this.questionTarget.value.trim() : ""
    if (question.length === 0) {
      event.preventDefault()
      this.#showError("Please enter a question for AI.")
      return
    }

    this.clearError()
    this.#setLoading(true)
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }

    if (this.hasServerMessageTarget) {
      this.serverMessageTarget.classList.add("hidden")
    }
  }

  #setLoading(isLoading) {
    if (this.hasButtonTarget) this.buttonTarget.disabled = isLoading
    if (this.hasButtonTextTarget) this.buttonTextTarget.textContent = isLoading ? "Asking AI..." : "Ask AI about this"
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.toggle("hidden", !isLoading)
    if (this.hasLoadingTarget) this.loadingTarget.classList.toggle("hidden", !isLoading)
  }

  #showError(message) {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }
}
