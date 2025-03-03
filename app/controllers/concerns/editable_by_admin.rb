module EditableByAdmin
  extend ActiveSupport::Concern

  included do
    def editable_by_admin_params(required_params)
      required_params.permit(:body, :zendesk_ticket_url)
    end
  end
end
