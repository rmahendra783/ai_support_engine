module Support
  class ProcessTicketAiJob < ApplicationJob
    queue_as :default

    def perform(ticket_id)
      ticket = Support::Ticket.find_by(id: ticket_id)
      return unless ticket

      # Step 1: Categorization & Embedding
      result = Ai::TicketAnalyzerService.new(ticket).call

      ticket.update!(
        category: result[:category],
        priority: result[:priority],
        sentiment: result[:sentiment],
        embedding: result[:embedding],
        status: "processed"
      )

      # Step 2: RAG Auto-Draft Response
      draft = Ai::AutoResponseGeneratorService.new(ticket).call
      ticket.update_column(:suggested_reply, draft) if draft.present?
    rescue StandardError => e
      Rails.logger.error("[Job Failed] Support::ProcessTicketAiJob: #{e.message}")
      ticket&.update(status: "failed")
    end
  end
end
