module API
  module V3
    class StatementsController < BaseController
      include FilterByDate
      include FilterByRegistrationPeriod

      def index = head(:method_not_allowed)
      def show = head(:method_not_allowed)
    end
  end
end
