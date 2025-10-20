module API
  module ErrorRescuable
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
      rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
      rescue_from ActionController::BadRequest, with: :bad_request_response
      rescue_from ActionController::ParameterMissing, with: :parameters_missing_response
      rescue_from ArgumentError, with: :bad_request_response
    end

    private

    def unpermitted_parameter_response(exception)
      render json: {errors: API::Errors::Response.new(title: "Unpermitted parameters", messages: exception.params).call}, status: :unprocessable_content
    end

    def bad_request_response(exception)
      render json: {errors: API::Errors::Response.new(title: "Bad request", messages: exception.message).call}, status: :bad_request
    end

    def not_found_response
      render json: {errors: API::Errors::Response.new(title: "Resource not found", messages: "Nothing could be found for the provided details").call}, status: :not_found
    end

    def parameters_missing_response
      bad_request_error = ActionController::BadRequest.new("Correct json data structure required. See API docs for reference.")
      bad_request_response(bad_request_error)
    end
  end
end
