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
    end
  end
end
