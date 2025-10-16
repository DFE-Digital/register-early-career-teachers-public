module TRS
  module RetryableClient
    extend ActiveSupport::Concern

    included do
      retry_on Errors::APIRequestError,
        wait: ->(executions) { 2**executions },
        attempts: 15
    end

    private

    def api_client
      @api_client ||= TRS::APIClient.build
    end
  end
end
