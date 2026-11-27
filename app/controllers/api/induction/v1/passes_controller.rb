module API
  module Induction
    module V1
      class PassesController < ActionController::API
        include API::OAuth::TokenAuthenticable
        include API::Induction::ErrorHandleable

        def create
          induction = API::AppropriateBodies::Induction.new(appropriate_body:, client:)
          pass = induction.pass!(**pass_params)

          render json: API::Induction::V1::PassSerializer.render(pass), status: :ok
        end

      private

        def pass_params = API::Induction::V1::PassRequest.parse(params)
      end
    end
  end
end
