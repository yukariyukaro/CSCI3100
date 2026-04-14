class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User", inverse_of: :messages

  validates :content, presence: true

  after_create_commit :broadcast_to_conversation

  private

  def broadcast_to_conversation
    ActionCable.server.broadcast(
      "conversation_#{conversation_id}",
      {
        id: id,
        content: content,
        sender_id: sender_id,
        sender_name: sender.name,
        created_at: created_at.strftime("%H:%M")
      }
    )
  end
end
