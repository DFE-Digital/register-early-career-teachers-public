module DfESignIn
  class AccessRequestJob < ApplicationJob
    # We want to discard all jobs that result in error responses, except those
    # that result in 500 errors, which we want to retry.
    discard_on APIClient::ResponseError do |_job, error|
      Sentry.capture_exception(error, level: :error)
    end
    retry_on APIClient::InternalServerError, wait: :polynomially_longer, attempts: 14

    def perform(organisation_id:, user_id:, role_ids:)
      api_client.access_requests(organisation_id:, user_id:, role_ids:)
    end

  private

    def api_client = DfESignIn::APIClient.new
  end
end
