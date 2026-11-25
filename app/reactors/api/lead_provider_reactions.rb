module API
  module LeadProviderReactions
    extend ActiveSupport::Concern

  private

    def emit_reaction_events!(resource:, in_reaction_to:)
      resource.lead_providers.find_each do |lead_provider|
        emit_created_or_updated_reaction_event!(resource:, lead_provider:, in_reaction_to:)
      end

      resource.lead_providers_no_longer_involved.find_each do |lead_provider|
        record_reaction_event!(action: :deleted, resource:, lead_provider:, in_reaction_to:, payload: nil)
      end
    end

    def emit_created_or_updated_reaction_event!(resource:, lead_provider:, in_reaction_to:)
      payload = payload_for(resource:, lead_provider:)
      latest_emitted_payload = resource.latest_emitted_payload(lead_provider:)
      return if latest_emitted_payload == payload

      action = latest_emitted_payload.nil? ? :created : :updated
      record_reaction_event!(action:, resource:, lead_provider:, in_reaction_to:, payload:)
    end

    def payload_for(resource:, lead_provider:) = raise(NotImplementedError)

    def record_reaction_event!(action:, resource:, lead_provider:, in_reaction_to:, payload:) = raise(NotImplementedError)
  end
end
