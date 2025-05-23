module API
  module V3
    class StatementsController < BaseController
      def index
        # Temp to demonstrate pagination.
        render json: { data: paginate(Statement.all) }.to_json
      end

      def show = head(:method_not_allowed)
    end
  end
end
