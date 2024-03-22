
namespace :embeddings do
  desc "Fetch turbo documentation AND create embeddings"
  task create: :environment do
    open_ai_url = 'https://api.openai.com'
    open_ai_headers = {
      'Authorization': "Bearer #{Rails.application.credentials.dig(:open_ai, :secret_key)}"
    }
    version = 1

    urls = [
      "https://turbo.hotwired.dev/handbook/introduction",
      "https://turbo.hotwired.dev/handbook/drive",
      "https://turbo.hotwired.dev/handbook/page_refreshes",
      "https://turbo.hotwired.dev/handbook/frames",
      "https://turbo.hotwired.dev/handbook/streams",
      "https://turbo.hotwired.dev/handbook/native",
      "https://turbo.hotwired.dev/handbook/building",
      "https://turbo.hotwired.dev/handbook/installing",
      "https://turbo.hotwired.dev/reference/drive",
      "https://turbo.hotwired.dev/reference/frames",
      "https://turbo.hotwired.dev/reference/streams",
      "https://turbo.hotwired.dev/reference/events",
      "https://turbo.hotwired.dev/reference/attributes"
    ]

    @open_ai_connection = Faraday.new(url: open_ai_url, headers: open_ai_headers) do |f|
      f.request :json
      f.response :json
    end

    urls.each do |url|
      @doc_connection = Faraday.new(url: url)

      file_name = url.split("/").last

      response = @doc_connection.get
      doc_html_content = Nokogiri::HTML(response.body).css("section.docs__content").first.text
      number_of_slice = doc_html_content.size / 2000

      puts "#{file_name}: #{number_of_slice}"

      number_of_slice.times do |x|
        puts "SLICE #{x+1}"
        text = doc_html_content.slice(x, 2000*(x+1))
        embedding = Embedding.create(url: url, version: version, text: text)

        body = {
          input: text,
          model: "text-embedding-ada-002",
          encoding_format: "float"
        }

        request = @open_ai_connection.post('/v1/embeddings', body)
        vector = request.body.dig("data")[0].dig("embedding")

        embedding.update(embedding: vector)
        sleep 0.5
      end
    end
  end
end
