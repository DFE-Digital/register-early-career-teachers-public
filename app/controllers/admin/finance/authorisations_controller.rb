module Admin::Finance
  class AuthorisationsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_statement
    before_action :set_form

    def new
    end

    def create
      if @form.valid?
        authorise_payment!
        flash[:alert] = "Statement authorisation processing"
        redirect_to admin_finance_statement_path(@statement)
      else
        render :new, status: :unprocessable_content
      end
    end

  private

    def set_statement
      statement = Statement.includes(active_lead_provider: :lead_provider).find(params[:finance_statement_id])
      @statement = Admin::StatementPresenter.new(statement)
    end

    def set_form
      @form = Admin::Finance::AuthorisePaymentForm.new(**form_params)
    end

    def form_params
      return {} unless params.key?(:admin_finance_authorise_payment_form)

      params.expect(admin_finance_authorise_payment_form: [:confirmed])
    end

    def authorise_payment!
      # TODO: run in a background job
      Statements::AuthorisePayment.new(@statement.__getobj__, author: current_user).authorise!
    end
  end
end
