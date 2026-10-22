module DfESignIn
  class AccessRequestJob < ApplicationJob
    def perform(organisation_id:, user_id:, role_ids:)
      api_client.access_requests(organisation_id:, user_id:, role_ids:)
    end

  private

    def api_client = DfESignIn::APIClient.new
  end
end
