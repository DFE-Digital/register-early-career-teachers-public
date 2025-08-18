module AuditableParams
  extend ActiveSupport::Concern

private

  def auditable_params
    params.permit(:support_ticket_url, :note)
  end
end
