class OpenAi::Chat::CreateMessageJob
  include Sidekiq::Job

  URL = 'https://api.openai.com'
  HEADER = {
    'Authorization': "Bearer #{Rails.application.credentials.dig(:open_ai, :secret_key)}"
  }

  def perform(args)
    payload = JSON.parse(args)
    @assistant_message = Message.find(payload["message_id"])

    @messages_attributes = @assistant_message.chat
      .messages.where.not(id: @assistant_message.id).first(10)
      .map{ |msg| msg.attributes.slice("role", "content") }

    @connection = Faraday.new(url: URL, headers: HEADER) do |f|
      f.request :json
      f.response :json
    end

    body = {
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are just a helpful assistant."
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
          @assistant_message.update(content: content)
        else
          events.map{ |x| JSON.parse(x) }.each do |event|
            content_from_event = event.dig("choices", 0, "delta", "content") || ""
            content = content + content_from_event
          end
          @assistant_message.content = content
        end
        Turbo::StreamsChannel.broadcast_render_to(
          "chat_#{@assistant_message.chat.id}",
          partial: "messages/job_message_update",
          locals: { message: @assistant_message }
        )
        rescue JSON::ParserError => e
          next
        end
      end
    end
  end
end
