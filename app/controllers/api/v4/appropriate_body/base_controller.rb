module API
  module V4
    module AppropriateBody
      # SPIKE: authentication is deferred to a separate PR. For now every request
      # acts as the "Golden Leaf" appropriate body.
      class BaseController < APIController
        skip_before_action :authenticate # skip for spike

        rescue_from AppropriateBodies::CloseInduction::TeacherHasNoOngoingInductionPeriod, with: :not_found_response

        rescue_from ActiveModel::ValidationError do |exception|
          render json: API::Errors::Response.from(exception.model), status: :unprocessable_content
        end

        rescue_from ActiveRecord::RecordInvalid do |exception|
          render json: API::Errors::Response.from(exception.record), status: :unprocessable_content
        end

      private

        # SPIKE: hardcoded default appropriate body
        def appropriate_body_period
          @appropriate_body_period ||= AppropriateBodyPeriod.find_by!(name: "Golden Leaf Teaching School Hub")
        end

        def author
          @author ||= Events::AppropriateBodyAPIAuthor.new(appropriate_body_period:, email: "spike@example.com")
        end
      end
    end
  end
end
