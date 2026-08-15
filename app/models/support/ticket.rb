module Support
  class Ticket < ApplicationRecord
    self.table_name = "tickets"

    has_neighbors :embedding

    validates :title, :description, presence: true

    enum :status, { pending: "pending", processed: "processed", failed: "failed" }

    after_commit :enqueue_ai_processing, on: :create

    # Semantic vector search via local Ollama
    def self.semantic_search(query_text, limit: 5)
      return none if query_text.blank?

      client = OpenAI::Client.new(
        access_token: "ollama",
        uri_base: "http://localhost:11434/v1"
      )

      response = client.embeddings(
        parameters: {
          model: Ai::TicketAnalyzerService::EMBEDDING_MODEL,
          input: query_text
        }
      )
      query_vector = response.dig("data", 0, "embedding")

      # Guard clause: Agar vector generate na ho sake toh empty result return karein
      return none unless query_vector

      nearest_neighbors(:embedding, query_vector, distance: "cosine").limit(limit)
    rescue StandardError => e
      Rails.logger.error("[Semantic Search Error]: #{e.message}")
      none
    end

    private

    def enqueue_ai_processing
      Support::ProcessTicketAiJob.perform_later(id)
    end
  end
end