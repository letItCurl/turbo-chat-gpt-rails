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

    embeddings = get_embeddings(@messages_attributes.last["content"])
    urls_used = embeddings.map{ |el| el["url"] }.uniq.join("\n ")
    similar_texts = embeddings.map{ |el| el["text"] }.uniq.join("\n ")
    body = {
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are just a helpful assistant. You are supposed to answers question about Turbo, the new feature in rails 7. Here is some extra information: #{similar_texts}"
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
          @assistant_message.update(content: "#{content} \n\n Documentation: #{urls_used}")
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

  def get_embeddings(text)
    body = {
      input: text,
      model: "text-embedding-ada-002",
      encoding_format: "float"
    }

    request = @connection.post("/v1/embeddings", body)

    embedding = request.body.dig("data")[0].dig("embedding")

    ActiveRecord::Base.connection.execute("SELECT url, text, 1 - (embedding <=> '#{embedding}') AS cosine_similarity FROM embeddings;").first(3)
  end
end
