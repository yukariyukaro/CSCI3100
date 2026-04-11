import consumer from "channels/consumer"

// ChatChannel is initialised per-conversation from the chat Stimulus controller.
// See app/javascript/controllers/chat_controller.js
export function subscribeToConversation(conversationId, currentUserId, callbacks = {}) {
  const onMessage = callbacks.onMessage
  const onMaintenance = callbacks.onMaintenance
  const onConnected = callbacks.onConnected
  const onDisconnected = callbacks.onDisconnected
  const onRejected = callbacks.onRejected

  return consumer.subscriptions.create(
    { channel: "ChatChannel", conversation_id: conversationId },
    {
      connected() {
        onConnected?.()
      },

      disconnected() {
        onDisconnected?.()
      },

      rejected() {
        onRejected?.()
      },

      received(data) {
        if (data && data.type === "maintenance") {
          onMaintenance?.(data)
          return
        }
        onMessage?.(data, currentUserId)
      }
    }
  )
}
