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

        def claim_params
          params.expect(claim: %i[date_of_birth started_on training_programme])
                .merge(trn: params[:teacher_trn]).to_h.symbolize_keys
        end
      end
    end
  end
end
