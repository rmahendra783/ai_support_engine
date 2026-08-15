module Ai
  class TicketAnalyzerService
    EMBEDDING_MODEL = "nomic-embed-text"
    CHAT_MODEL = "llama3.2:1b"

    def initialize(ticket)
      @ticket = ticket
      # Local Ollama endpoint point kiya gaya hai (100% Free)
      @client = OpenAI::Client.new(
        access_token: "ollama",
        uri_base: "http://localhost:11434/v1"
      )
    end

    def call
      classification = extract_classification
      vector = generate_vector

      {
        category: classification["category"],
        priority: classification["priority"],
        sentiment: classification["sentiment"],
        embedding: vector
      }
    end

    private

    # 1. Local LLM se structured JSON output nikalna
    def extract_classification
      prompt = <<~PROMPT
        Analyze this customer support ticket.
        Respond ONLY with a valid JSON object (no markdown formatting, no backticks, no conversational text) matching this schema:
        {
          "category": "Billing" | "Technical" | "Account" | "Security" | "Feature Request",
          "priority": "Low" | "Medium" | "High" | "Critical",
          "sentiment": "Positive" | "Neutral" | "Frustrated" | "Angry"
        }

        Title: #{@ticket.title}
        Description: #{@ticket.description}
      PROMPT

      response = @client.chat(
        parameters: {
          model: CHAT_MODEL,
          messages: [{ role: "user", content: prompt }],
          response_format: { type: "json_object" }
        }
      )

      raw_content = response.dig("choices", 0, "message", "content")
      JSON.parse(raw_content)
    rescue StandardError => e
      Rails.logger.error("[AI Classification Error] Ticket ##{@ticket.id}: #{e.message}")
      { "category" => "Unassigned", "priority" => "Medium", "sentiment" => "Neutral" }
    end

    # 2. nomic-embed-text se 768-dimension vector generate karna
    def generate_vector
      text_payload = "#{@ticket.title}\n#{@ticket.description}"
      response = @client.embeddings(
        parameters: {
          model: EMBEDDING_MODEL,
          input: text_payload
        }
      )
      response.dig("data", 0, "embedding")
    rescue StandardError => e
      Rails.logger.error("[AI Embedding Error] Ticket ##{@ticket.id}: #{e.message}")
      nil
    end
  end
end