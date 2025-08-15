module API
  # https://github.com/DFE-Digital/dfe-analytics/blob/main/lib/dfe/analytics/requests.rb
  # With custom event type
  module DfEAnalyticsRequests
    extend ActiveSupport::Concern

    included do
      after_action :trigger_web_request_event
    end

    include Dfe::Analytics::Concerns::Requestable

    def trigger_web_request_event
      trigger_request_event(:persist_api_request)
    end

  private

    # `current_user` needed for DfE::Analytics
    def current_user
      current_lead_provider
    end
  end
end
