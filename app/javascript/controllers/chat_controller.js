import { Controller } from "@hotwired/stimulus"
import { subscribeToConversation } from "channels/chat_channel"

// Stimulus controller for a single conversation chat room.
// Usage: data-controller="chat"
//        data-chat-conversation-id-value="<%= @conversation.id %>"
//        data-chat-current-user-id-value="<%= current_user.id %>"
export default class extends Controller {
  static targets = ["messages", "input", "form", "status"]
  static values = { conversationId: Number, currentUserId: Number }

  connect() {
    this.setStatus("")
    this.setFormEnabled(false)

    this.subscription = subscribeToConversation(this.conversationIdValue, this.currentUserIdValue, {
      onMessage: this.appendMessage.bind(this),
      onConnected: () => {
        this.setStatus("")
        this.setFormEnabled(true)
        this.syncMissingMessages()
      },
      onDisconnected: () => {
        this.setStatus("Disconnected. Reconnecting…")
        this.setFormEnabled(false)
      },
      onMaintenance: (data) => {
        this.setStatus(data?.message || "Demo data reset. Please refresh.")
        this.setFormEnabled(false)
      },
      onRejected: () => {
        this.setStatus("Chat unavailable for this conversation.")
        this.setFormEnabled(false)
        this.subscription?.unsubscribe()
      }
    })

    this.syncMissingMessages()
    this.scrollToBottom()
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  // Called when the send form is submitted
  send(event) {
    event.preventDefault()
    const content = this.inputTarget.value.trim()
    if (!content) return

    this.setFormEnabled(false)

    fetch(this.formTarget.action, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({ message: { content } })
    })
      .then((resp) => {
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
        this.inputTarget.value = ""
        this.setStatus("")
      })
      .catch(() => {
        this.setStatus("Failed to send message.")
      })
      .finally(() => {
        this.setFormEnabled(true)
      })
  }

  // Called by ActionCable when a new message arrives
  appendMessage(data, currentUserId) {
    const isSelf = data.sender_id === currentUserId
    const bubble = document.createElement("div")
    bubble.className = `chat ${isSelf ? "chat-end" : "chat-start"}`
    bubble.dataset.messageId = data.id
    bubble.innerHTML = `
      <div class="chat-header text-xs opacity-60 mb-1">${isSelf ? "You" : this.escapeHtml(data.sender_name)} <time class="ml-1">${data.created_at}</time></div>
      <div class="chat-bubble ${isSelf ? "chat-bubble-primary" : ""}">${this.escapeHtml(data.content)}</div>
    `
    this.messagesTarget.appendChild(bubble)
    this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  syncMissingMessages() {
    const last = this.lastMessageId()
    const url = `/conversations/${this.conversationIdValue}/messages.json?after_id=${encodeURIComponent(last)}`

    fetch(url, { headers: { "Accept": "application/json" } })
      .then((resp) => {
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
        return resp.json()
      })
      .then((messages) => {
        messages.forEach((m) => this.appendMessage(m, this.currentUserIdValue))
      })
      .catch(() => { })
  }

  lastMessageId() {
    const nodes = this.messagesTarget.querySelectorAll("[data-message-id]")
    if (nodes.length === 0) return 0
    const last = nodes[nodes.length - 1].getAttribute("data-message-id")
    return parseInt(last, 10) || 0
  }

  setFormEnabled(enabled) {
    this.inputTarget.disabled = !enabled
    const submit = this.formTarget.querySelector('input[type="submit"],button[type="submit"]')
    if (submit) submit.disabled = !enabled
  }

  setStatus(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("hidden", !message)
  }

  escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
