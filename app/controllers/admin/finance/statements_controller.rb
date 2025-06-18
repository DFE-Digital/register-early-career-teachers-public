module Admin::Finance
  class StatementsController < AdminController
    layout 'full'

    def index
      @pagy, statements = pagy(
        statements_query.statements.eager_load(active_lead_provider: %i[
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

  private

    def statements_query
      opts = {
        lead_provider:,
        registration_period_years:,
        statement_date:,
        output_fee:,
        order_by: :statement_date,
      }
      Statements::Query.new(**opts.compact)
    end

    def lead_provider
      id = filter_params[:lead_provider_id]
      LeadProvider.find(id) if id.present?
    end

    def registration_period_years
      filter_params[:registration_period_id].presence
    end

    def statement_date
      filter_params[:statement_date].presence
    end

    def output_fee
      case filter_params[:statement_type]
      when "output_fee"
        true
      when "service_fee"
        false
      when "all"
        :ignore
      else
        true
      end
    end

    def filter_params
      params.permit(:lead_provider_id, :registration_period_id, :statement_date, :statement_type)
    end

    helper_method :filter_params
  end
end
