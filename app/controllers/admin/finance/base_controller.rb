module Admin
  module Finance
    class BaseController < AdminController
      before_action :authorise_finance

    private

      def authorise_finance
        return if current_user&.dfe_user? && current_user.finance_access?

        @unauthorised_context = :finance
        render "errors/unauthorised", status: :unauthorized
      end
    end
  end
end
