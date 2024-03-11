class Message < ApplicationRecord
  belongs_to :chat

  enum role: { user: "user", system: "system", assistant: "assistant" }


  validates :content, presence: true
  validates :role, presence: true

  after_create :create_assistant_message, if: -> { self.user? }
  after_update :udpate_chat_title, if: -> { self.chat.messages.count == 4 }

  private

  def create_assistant_message
    message = self.chat.messages.create(content: "...", role: "assistant")
    OpenAi::Chat::CreateMessageJob.perform_async({message_id: message.id}.to_json)
  end

  def udpate_chat_title
    OpenAi::Chat::UpdateChatTitleJob.perform_async({ chat_id: self.chat_id }.to_json)
  end
end
