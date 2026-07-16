class ActiveLeadProvider
  module EventRecordable
    extend ActiveSupport::Concern

    included do
      has_many :events

      after_create :record_created_event
    end

  private

    def record_created_event
      Events::Record.record_active_lead_provider_created_event!(author:, active_lead_provider: self)
    end
  end
end
