module API
  module ErrorRescuable
    extend ActiveSupport::Concern

    included do
      rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
      rescue_from ActionController::BadRequest, with: :bad_request_response
      rescue_from ArgumentError, with: :bad_request_response
      rescue_from API::Errors::FilterValidationError, with: :filter_validation_error_response
    end

  private

    def unpermitted_parameter_response(exception)
      render json: { errors: API::Errors::Response.new(error: "Unpermitted parameters", params: exception.params).call }, status: :unprocessable_entity
    end

    def bad_request_response(exception)
      render json: { errors: API::Errors::Response.new(error: "Bad request", params: exception.message).call }, status: :bad_request
    end

    def filter_validation_error_response(exception)
      render json: { errors: API::Errors::Response.new(error: "Unpermitted parameters", params: exception.message).call }, status: :unprocessable_entity
    end
  end
end
