module API
  module Induction
    module V1
      class ReleasesController < ActionController::API
        include API::OAuth::TokenAuthenticable
        include API::Induction::ErrorHandleable

        def create
          induction = API::AppropriateBodies::Induction.new(appropriate_body:, client:)
          release = induction.release!(**release_params)

          render json: API::Induction::V1::ReleaseSerializer.render(release), status: :ok
        end

      private

        def release_params = API::Induction::V1::ReleaseRequest.parse(params)
      end
    end
  end
end
