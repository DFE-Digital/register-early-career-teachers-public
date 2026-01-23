class SupportQuery
  class SendToZendeskJob < ApplicationJob
    def perform(support_query)
      support_query.send_to_zendesk_now
    end
  end
end
