import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "error", "submit", "form", "paymentIntentInput"]
  static values = {
    publishableKey: String,
    clientSecret: String,
    paymentIntentId: String
  }

  connect() {
    if (!this.publishableKeyValue || !this.clientSecretValue || typeof Stripe === "undefined") {
      this.renderError("Stripe is not configured correctly.")
      return
    }

    this.stripe = Stripe(this.publishableKeyValue)
    this.elements = this.stripe.elements()
    this.cardElement = this.elements.create("card")
    this.cardElement.mount(this.cardTarget)
  }

  async submit() {
    this.clearError()
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Processing..."

    const result = await this.stripe.confirmCardPayment(this.clientSecretValue, {
      payment_method: {
        card: this.cardElement
      }
    })

    if (result.error) {
      this.renderError(result.error.message)
      this.resetButton()
      return
    }

    if (!result.paymentIntent || !["succeeded", "processing", "requires_capture"].includes(result.paymentIntent.status)) {
      this.renderError("Payment was not completed. Please try again.")
      this.resetButton()
      return
    }

    this.paymentIntentInputTarget.value = result.paymentIntent.id || this.paymentIntentIdValue
    this.formTarget.requestSubmit()
  }

  renderError(message) {
    this.errorTarget.textContent = message
  }

  clearError() {
    this.errorTarget.textContent = ""
  }

  resetButton() {
    this.submitTarget.disabled = false
    this.submitTarget.textContent = "Confirm Payment"
  }
}
