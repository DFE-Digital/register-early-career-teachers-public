module Admin::Finance
  class StatementsController < AdminController
    layout 'full'

    def index
      @pagy, statements = pagy(
        Statements::Query.new.statements.eager_load(active_lead_provider: %i[
          lead_provider
          registration_period
        ])
      )

      @statements = Admin::StatementPresenter.wrap(statements)
    end

    def show
      statement = Statement.eager_load(active_lead_provider: :lead_provider).find(params[:id])

      @statement = Admin::StatementPresenter.new(statement)
    end
  end
end
