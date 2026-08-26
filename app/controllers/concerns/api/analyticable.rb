module API
  module Analyticable
    extend ActiveSupport::Concern

    included do
      include DfE::Analytics::Requests
    end

    def current_user
      API::AnalyticsUser.new(current_lead_provider)
    end

    def append_info_to_payload(payload)
      super
      payload[:current_user_class] = current_lead_provider&.class&.name
      payload[:current_user_id] = current_lead_provider&.id
    end
  end
end
