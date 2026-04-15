import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "description", "condition", "price", "output", "button", "endpoint"]

  async suggest(event) {
    event.preventDefault()
    this.#cancelOngoingRequest()
    this.#setLoading(true)
    this.#render("")
    this.abortController = new AbortController()

    try {
      const body = {
        name: this.nameTarget.value,
        description: this.descriptionTarget.value,
        condition: this.conditionTarget.value
      }

      const response = await fetch(this.#priceSuggestionUrl(), {
        method: "POST",
        signal: this.abortController.signal,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.#csrfToken()
        },
        body: JSON.stringify(body)
      })

      const data = await response.json()
      if (data.status === "ok") {
        this.priceTarget.value = data.recommended_price
        this.#render(`AI Suggestion: HK$${data.recommended_price} (Range: HK$${data.min_price} - HK$${data.max_price}). ${this.#escape(data.reasoning)}`)
      } else {
        this.#render(this.#escape(data.message || "AI pricing is unavailable now."))
      }
    } catch (error) {
      if (error.name === "AbortError") return
      this.#render("AI pricing is unavailable now.")
    } finally {
      this.#setLoading(false)
      this.abortController = null
    }
  }

  cancel() {
    this.#cancelOngoingRequest()
    this.#setLoading(false)
  }

  #setLoading(isLoading) {
    if (!this.hasButtonTarget) return

    this.buttonTarget.disabled = isLoading
    this.buttonTarget.textContent = isLoading ? "AI Suggesting..." : "AI Suggest Price"
  }

  #cancelOngoingRequest() {
    if (this.abortController) {
      this.abortController.abort()
    }
  }

  #render(text) {
    if (!this.hasOutputTarget) return

    if (text.length === 0) {
      this.outputTarget.classList.add("hidden")
      this.outputTarget.textContent = ""
      return
    }

    this.outputTarget.classList.remove("hidden")
    this.outputTarget.textContent = text
  }

  #csrfToken() {
    const node = document.querySelector('meta[name="csrf-token"]')
    return node ? node.content : ""
  }

  #priceSuggestionUrl() {
    if (this.hasEndpointTarget && this.endpointTarget.value.length > 0) {
      return this.endpointTarget.value
    }

    return "/api/listings/price_suggestion"
  }

  #escape(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
