module API
  module Induction
    module V1
      class AppropriateBodiesController < ActionController::API
        include API::OAuth::ClientAuthenticable

        def index
          appropriate_bodies = AppropriateBodyPeriod.active.order(:name)

          render json: API::Induction::V1::AppropriateBodySerializer.render(appropriate_bodies)
        end
      end
    end
  end
end
