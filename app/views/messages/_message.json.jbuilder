json.extract! message, :id, :chat_id, :content, :role, :created_at, :updated_at
json.url message_url(message, format: :json)
