import { Controller } from "@hotwired/stimulus"

// Polls /api/products/:id/ai_summary every few seconds while status is pending/generating.
// When the summary is ready it replaces the card content in place without a full page reload.
export default class extends Controller {
  static values = {
    productId: Number,
    pollInterval: { type: Number, default: 3000 }
  }

  connect() {
    // pollIntervalValue == 0 means the status is already terminal (completed/failed/skipped)
    if (this.pollIntervalValue > 0) {
      this.#startPolling()
    }
  }

  disconnect() {
    this.#stopPolling()
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  #startPolling() {
    this.#poll() // immediate first check
    this._timer = setInterval(() => this.#poll(), this.pollIntervalValue)
  }

  #stopPolling() {
    if (this._timer) {
      clearInterval(this._timer)
      this._timer = null
    }
  }

  async #poll() {
    try {
      const res = await fetch(`/api/products/${this.productIdValue}/ai_summary`, {
        headers: { Accept: "application/json" }
      })
      if (!res.ok) { this.#stopPolling(); return }

      const data = await res.json()

      if (data.ai_summary_status === "completed" && data.ai_summary) {
        this.#renderCompleted(data.ai_summary, data.ai_model)
        this.#stopPolling()
      } else if (["failed", "skipped"].includes(data.ai_summary_status)) {
        this.#renderHidden()
        this.#stopPolling()
      }
      // else: still pending/generating — keep polling
    } catch (_err) {
      // Network error — stop to avoid spam
      this.#stopPolling()
    }
  }

  #renderCompleted(summary, model) {
    // Build bullet lines from the summary text
    const lines = summary.split("\n").filter(l => l.trim().length > 0)
    const bullets = lines.map(l => `<p class="leading-relaxed">${this.#escapeHtml(l)}</p>`).join("")

    this.element.innerHTML = `
      <div class="card bg-base-200 border-l-4 border-primary shadow-sm animate-fade-in">
        <div class="card-body p-4">
          <h3 class="card-title text-primary text-sm flex items-center gap-1 mb-2">
            ✨ AI Key Selling Points
          </h3>
          <div class="leading-relaxed text-sm text-base-content/80">${bullets}</div>
          <span class="text-xs text-base-content/40 mt-2 block">Auto-generated · for reference only</span>
        </div>
      </div>`
  }

  #renderHidden() {
    this.element.innerHTML = ""
  }

  #escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
