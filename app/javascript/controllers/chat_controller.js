import { Controller } from "@hotwired/stimulus"
import { subscribeToConversation } from "channels/chat_channel"

// Stimulus controller for a single conversation chat room.
// Usage: data-controller="chat"
//        data-chat-conversation-id-value="<%= @conversation.id %>"
//        data-chat-current-user-id-value="<%= current_user.id %>"
export default class extends Controller {
  static targets = ["messages", "input", "form"]
  static values  = { conversationId: Number, currentUserId: Number }

  connect() {
    this.subscription = subscribeToConversation(
      this.conversationIdValue,
      this.currentUserIdValue,
      this.appendMessage.bind(this)
    )
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

    fetch(this.formTarget.action, {
      method:  "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        "Accept":       "application/json"
      },
      body: JSON.stringify({ message: { content } })
    })

    // Optimistically clear the input; the server will broadcast the real message
    this.inputTarget.value = ""
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

  escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
