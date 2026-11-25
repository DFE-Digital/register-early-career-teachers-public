module LeadProviderEventTrackable
  extend ActiveSupport::Concern

  included do
    has_many :api_reaction_events, -> { api_reaction_events }, class_name: "Event" do
      def latest_relevant_timestamp(lead_provider:)
        api_creation_and_update_reaction_events.where(lead_provider:).maximum(:happened_at)
      end

      def latest_emitted_payload(lead_provider:)
        where(lead_provider:).order(:id).last&.metadata&.dig("payload")
      end

      def lead_providers_no_longer_involved
        latest_event_ids = group(:lead_provider_id).select("MAX(events.id)")

        LeadProvider
          .where(id: Event.api_creation_and_update_reaction_events.where(id: latest_event_ids).select(:lead_provider_id))
          .where.not(id: proxy_association.owner.lead_providers.select(:id))
      end
    end

    delegate :latest_relevant_timestamp, :latest_emitted_payload, :lead_providers_no_longer_involved, to: :api_reaction_events
  end
end
