module API
  class BaseController < ActionController::API
    include TokenAuthenticatable
    include Paginatable
    include ErrorRescuable
    include DateFilterable
    include ContractPeriodFilterable
    include FilterValidatable
    include DfE::Analytics::Requests

  private

    # `current_user` needed for DfE::Analytics
    def current_user
      current_lead_provider
    end

  protected

    def respond_with_service(service:, action:)
      if service.valid?
        render json: to_json(service.send(action))
      else
        render json: API::Errors::Response.from(service), status: :unprocessable_content
      end
    end
  end
end
