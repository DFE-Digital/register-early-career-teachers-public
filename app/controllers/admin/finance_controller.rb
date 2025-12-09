module Admin
  class FinanceController < AdminController
    def show
    end

  private

    def authorised?
      current_user&.dfe_user? && current_user.finance_access?
    end

    def authorise
      return if authorised?

      @unauthorised_context = :finance
      render "errors/unauthorised", status: :unauthorized
    end
  end
end
