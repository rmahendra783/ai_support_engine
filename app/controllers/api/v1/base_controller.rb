module Api
  module V1
    class BaseController < ActionController::API
      # Global error handlers for API
      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: e.message }, status: :not_found
      end
    end
  end
end