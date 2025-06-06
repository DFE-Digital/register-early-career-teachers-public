module API
  class AddAPITokenToLeadProvider
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider_name_or_id, :string
    attribute :logger, default: -> { Rails.logger }

    def add
      check_params!

      logger.info "AddAPITokenToLeadProvider: Started!"

      ActiveRecord::Base.transaction do
        Array.wrap(lead_provider || LeadProvider.all).each do |lp|
          add_api_token_to_lead_provider(lp)
        end
      end

      logger.info "AddAPITokenToLeadProvider: Finished!"
    end

    def lead_provider
      @lead_provider ||= LeadProvider.find_by(id: lead_provider_name_or_id) ||
        LeadProvider.find_by(name: lead_provider_name_or_id)
    end

  private

    def add_api_token_to_lead_provider(lead_provider)
      logger.info "AddAPITokenToLeadProvider: Adding API Token for Lead provider #{lead_provider.name}"

      api_token = API::TokenManager.create_lead_provider_api_token!(lead_provider:)

      logger.info "AddAPITokenToLeadProvider: API Token #{api_token.token} successfully added to Lead provider #{lead_provider.name}"
    end

    def check_params!
      raise("LeadProvider not found") if lead_provider_name_or_id && !lead_provider
    end
  end
end
