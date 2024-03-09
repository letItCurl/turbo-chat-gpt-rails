json.extract! message, :id, :chat_id, :content, :message_type, :created_at, :updated_at
json.url message_url(message, format: :json)
