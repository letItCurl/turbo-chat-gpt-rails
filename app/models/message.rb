class Message < ApplicationRecord
  belongs_to :chat

  enum role: { user: "user", system: "system", assistant: "assistant" }


  validates :content, presence: true
  validates :role, presence: true

  after_create :create_assistant_message, if: -> { self.user? }

  private

  def create_assistant_message
    message = self.chat.messages.create(content: "...", role: "assistant")
    OpenAi::Chat::CreateMessageJob.perform_async({message_id: message.id}.to_json)
  end
end
