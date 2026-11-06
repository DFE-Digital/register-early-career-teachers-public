module API
  module ServiceRespondable
    extend ActiveSupport::Concern

    def respond_with_service(service:, action:)
      if service.valid?
        response = service.send(action)
        response.reload if response.respond_to?(:reload)
        render json: to_json(response)
      else
        render json: API::Errors::Response.from(service), status: :unprocessable_content
      end

    # Can happen if the record becomes invalid between validation and creation.
    rescue ActiveRecord::RecordInvalid
      # Re-raise if the service is still valid (indicating an unexpected error occurred).
      raise if service.valid?

      # Otherwise, we re-validated and found the service to be invalid, so we return the errors.
      render json: API::Errors::Response.from(service), status: :unprocessable_content
    end
  end
end
