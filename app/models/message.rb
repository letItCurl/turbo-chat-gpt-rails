class Message < ApplicationRecord
  belongs_to :chat

  enum role: { user: "user", system: "system", assistant: "assistant" }


  validates :content, presence: true
  validates :role, presence: true
end
