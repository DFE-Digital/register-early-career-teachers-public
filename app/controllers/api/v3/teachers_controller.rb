module API
  module V3
    class TeachersController < APIController
      # This endpoint is for demonstration purposes and to verify the AB delegated token works.
      # List the AB's active teachers.
      def index
        render json: current_appropriate_body.induction_periods.ongoing.map {
          ::Teachers::Name.new(it.teacher).full_name
        }
      end
    end
  end
end
