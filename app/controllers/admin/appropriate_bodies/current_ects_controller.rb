module Admin
  module AppropriateBodies
    class CurrentECTsController < AdminController
      layout 'full', only: 'index'

      def index
        @appropriate_body = AppropriateBody.find(params[:appropriate_body_id])

        @claimed_inductions_count = ::Teachers::Search.new(appropriate_bodies: @appropriate_body).search.count

        @pagy, @teachers = pagy(
          ::Teachers::Search.new(query_string: params[:q], appropriate_bodies: @appropriate_body).search,
          limit: 30
        )
      end
    end
  end
end
