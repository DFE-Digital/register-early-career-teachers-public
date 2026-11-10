module API
  module Induction
    module V1
      class AppropriateBodiesController < ActionController::API
        include API::OAuth::ClientAuthenticable

        def index
          render json: API::Induction::V1::AppropriateBodySerializer.render(appropriate_bodies)
        end

      private

        def appropriate_bodies
          AppropriateBodyPeriod.active.with_display_names.strict_loading.sort_by(&:display_name)
        end
      end
    end
  end
end
