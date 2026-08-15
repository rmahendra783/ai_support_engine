module Ai
  class AutoResponseGeneratorService
    CHAT_MODEL = "llama3.2:1b"

    def initialize(ticket)
      @ticket = ticket
      @client = OpenAI::Client.new(
        access_token: "ollama",
        uri_base: "http://localhost:11434/v1"
      )
    end

    def call
      # 1. RETRIEVE: Similar resolved tickets fetch karna
      similar_resolved_tickets = find_similar_resolved_tickets

      # Agar past context na mile, toh generic prompt fall back
      context_text = build_context(similar_resolved_tickets)

      # 2. AUGMENT & GENERATE: Context ke sath draft prompt call karna
      generate_draft(context_text)
    end

    private

    def find_similar_resolved_tickets
      return [] unless @ticket.embedding.present?

      # pgvector se top 2 nearest tickets jinka resolution available ho
      Support::Ticket
        .where.not(id: @ticket.id)
        .where.not(resolution: nil)
        .nearest_neighbors(:embedding, @ticket.embedding, distance: "cosine")
        .limit(2)
    end

    def build_context(tickets)
      return "No historical solutions found." if tickets.empty?

      tickets.map.with_index(1) do |t, index|
        <<~TICKET_CONTEXT
          [Past Ticket #{index}]
          Issue: #{t.title} - #{t.description}
          Resolution: #{t.resolution}
        TICKET_CONTEXT
      end.join("\n\n")
    end

    def generate_draft(context)
      prompt = <<~PROMPT
        You are an expert customer support agent.
        Draft a polite, professional, and accurate response to the customer's support ticket.
        Use the provided Historical Solutions as reference to ensure accuracy.

        --- Historical Solutions ---
        #{context}
        ----------------------------

        --- Current Customer Ticket ---
        Title: #{@ticket.title}
        Description: #{@ticket.description}
        Customer Sentiment: #{@ticket.sentiment}
        -------------------------------

        Draft Response:
      PROMPT

      response = @client.chat(
        parameters: {
          model: CHAT_MODEL,
          messages: [ { role: "user", content: prompt } ]
        }
      )

      response.dig("choices", 0, "message", "content")&.strip
    rescue StandardError => e
      Rails.logger.error("[RAG Draft Error] Ticket ##{@ticket.id}: #{e.message}")
      nil
    end
  end
end
