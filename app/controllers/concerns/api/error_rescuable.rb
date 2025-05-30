module API
  module ErrorRescuable
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
      rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
      rescue_from ActionController::BadRequest, with: :bad_request_response
      rescue_from ArgumentError, with: :bad_request_response
    end

  private

    def unpermitted_parameter_response(exception)
      render json: { errors: API::Errors::Response.new(error: "Unpermitted parameters", params: exception.params).call }, status: :unprocessable_entity
    end

    def bad_request_response(exception)
      render json: { errors: API::Errors::Response.new(error: "Bad request", params: exception.message).call }, status: :bad_request
    end

    def not_found_response
      render json: { errors: API::Errors::Response.new(error: "Resource not found", params: "Nothing could be found for the provided details").call }, status: :not_found
    end
  end
end
