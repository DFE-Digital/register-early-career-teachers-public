module API
  module Induction
    module V1
      class PassesController < ActionController::API
        include API::OAuth::TokenAuthenticable
        include API::Induction::ErrorHandleable

        def create
          induction = API::AppropriateBodies::Induction.new(appropriate_body:, client:)
          outcome = induction.pass!(**pass_params)

          render json: API::Induction::V1::OutcomeSerializer.render(outcome), status: :ok
        end

      private

        def pass_params
          params.expect(pass: %i[finished_on number_of_terms])
                .merge(trn: params[:teacher_trn]).to_h.symbolize_keys
        end
      end
    end
  end
end
