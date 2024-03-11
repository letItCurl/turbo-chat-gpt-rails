class OpenAi::Chat::UpdateChatTitleJob
  include Sidekiq::Job

  URL = 'https://api.openai.com'
  HEADER = {
    'Authorization': "Bearer #{Rails.application.credentials.dig(:open_ai, :secret_key)}"
  }

  def perform(args)
    payload = JSON.parse(args)
    @chat = Chat.find(payload["chat_id"])

    @messages_attributes = @chat.messages.map{ |msg| msg.attributes.slice("role", "content") }

    @connection = Faraday.new(url: URL, headers: HEADER) do |f|
      f.request :json
      f.response :json
    end

    body = {
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are given a chat and your job is to summarize it in less than 5 words. You can only answer the summary. No prefix, No key, just the title. Your content is being added to a UI so we really just need the summary. If you do more than 5 words. I kill you."
        },
        *@messages_attributes
      ],
      stream: true
    }
    content = ""
    @connection.post('/v1/chat/completions', body) do |request|
      request.options.on_data = Proc.new do |chunk, size|
        events = chunk.split("data: ").reject{ |x| x.blank? }
        begin
        if events.last.strip == "[DONE]"
          @chat.update(title: content)
        else
          events.map{ |x| JSON.parse(x) }.each do |event|
            content_from_event = event.dig("choices", 0, "delta", "content") || ""
            content = content + content_from_event
          end
          @chat.title = content
        end
        Turbo::StreamsChannel.broadcast_render_to(
          "chat_#{@chat.id}",
          partial: "chats/job_chat_update",
          locals: { chat: @chat }
        )
        rescue JSON::ParserError => e
          next
        end
      end
    end
  end
end
