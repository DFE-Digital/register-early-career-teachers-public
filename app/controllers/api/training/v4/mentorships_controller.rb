module API
  module Training
    module V4
      class MentorshipsController < ActionController::API
        include API::OAuth::TokenAuthenticable

        self.accept_legacy_lead_provider_api_tokens = true

        def index
          head :ok
        end
      end
    end
  end
end
