module AuditableParams
  extend ActiveSupport::Concern

private

  def auditable_params_for(model_name)
    params.expect(model_name.param_key => %i[zendesk_ticket_id note])
      .merge({ author: current_user })
  end
end
