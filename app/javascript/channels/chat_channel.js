import consumer from "channels/consumer"

// ChatChannel is initialised per-conversation from the chat Stimulus controller.
// See app/javascript/controllers/chat_controller.js
export function subscribeToConversation(conversationId, currentUserId, onMessage) {
  return consumer.subscriptions.create(
    { channel: "ChatChannel", conversation_id: conversationId },
    {
      connected() {
        console.log(`[ChatChannel] Connected to conversation ${conversationId}`)
      },

      disconnected() {
        console.log(`[ChatChannel] Disconnected from conversation ${conversationId}`)
      },

      received(data) {
        onMessage(data, currentUserId)
      }
    }
  )
}
