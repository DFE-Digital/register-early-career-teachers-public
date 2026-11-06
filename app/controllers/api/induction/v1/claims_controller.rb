module API
  module Induction
    module V1
      class ClaimsController < ActionController::API
        include API::OAuth::TokenAuthenticable
        include API::Induction::ErrorHandleable

        def create
          induction = API::AppropriateBodies::Induction.new(appropriate_body:, client:)
          claim = induction.claim!(**claim_params)

          render json: API::Induction::V1::ClaimSerializer.render(claim), status: :created
        end

      private

        def claim_params = API::Induction::V1::ClaimRequest.parse(params)
      end
    end
  end
end
