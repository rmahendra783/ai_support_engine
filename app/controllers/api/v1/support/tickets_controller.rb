module Api
  module V1
    module Support
      class TicketsController < Api::V1::BaseController
        # POST /api/v1/support/tickets
        def create
          ticket = ::Support::Ticket.new(ticket_params)

          if ticket.save
            render json: {
              message: "Ticket created and queued for AI analysis.",
              data: ticket
            }, status: :accepted
          else
            render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/support/tickets
        def index
          tickets = ::Support::Ticket.order(created_at: :desc).limit(50)
          render json: { data: tickets }
        end

        # GET /api/v1/support/tickets/search?q=payment+failed
        def search
          if params[:q].present?
            results = ::Support::Ticket.processed.semantic_search(params[:q])
            render json: { query: params[:q], count: results.size, data: results }
          else
            render json: { error: "Query parameter 'q' is required" }, status: :bad_request
          end
        end

        private

        def ticket_params
          params.require(:ticket).permit(:title, :description)
        end
      end
    end
  end
end
