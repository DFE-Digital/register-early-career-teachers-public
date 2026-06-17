module Admin::Finance::ActiveLeadProviders
  class StatementsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_active_lead_provider
    before_action :set_statement, only: %i[show edit update delete destroy]
    before_action :redirect_unless_addable, only: %i[new create]
    before_action :redirect_unless_editable, only: %i[edit update delete destroy]

    def index
      contract_period = @active_lead_provider.contract_period

      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @active_lead_provider.contract_period_year.to_s => admin_contract_period_path(contract_period),
        @active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(contract_period),
      }
      @pagy, @statements = pagy(@active_lead_provider.statements.order(year: :asc, month: :asc))
    end

    def show
      # This is idiomatic Rails, so we need a comment to keep sonarcube happy.
    end

    def new
      @statement = Statement.new
    end

    def create
      @statement = ::Statements::Create.new(author: current_user, params: statement_params).call

      redirect_to statement_path(@statement), notice: "Statement added"
    rescue ActiveRecord::RecordInvalid => e
      @statement = e.record
      render :new, status: :unprocessable_content
    end

    def edit
      # This is idiomatic Rails, so we need a comment to keep sonarcube happy.
    end

    def update
      ::Statements::Update.new(
        author: current_user,
        statement: @statement,
        params: statement_params
      ).call

      redirect_to statement_path(@statement), notice: "Statement updated"
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
    end

    def delete
      # This is our project specific pattern, so we need a comment to keep sonarcube happy.
    end

    def destroy
      ::Statements::Destroy.new(author: current_user, statement: @statement).call

      redirect_to statements_path, notice: "Statement deleted"
    rescue ::Statements::Destroy::DeletionError => e
      redirect_to statement_path(@statement), flash: { error: e.message }
    end

  private

    def set_active_lead_provider
      @active_lead_provider = ActiveLeadProvider
        .includes(:contract_period, :lead_provider)
        .find(params[:active_lead_provider_id])
    end

    def set_statement
      @statement = @active_lead_provider.statements.find(params[:id])
    end

    def redirect_unless_addable
      if @active_lead_provider.contract_period.payments_frozen?
        redirect_to statements_path,
                    flash: { error: "Statements cannot be added once the contract period is frozen" }
      end
    end

    def redirect_unless_editable
      unless @active_lead_provider.editable?
        redirect_to statements_path,
                    flash: {
                      error: "Statements cannot be changed once the contract period has started"
                    }
      end
    end

    # Restrict the contract to this active lead provider's own contracts, so a
    # forged contract_id is nilled out and rejected by the presence validation
    # rather than attaching the statement to a different provider.
    def statement_params
      permitted = params.expect(statement: %i[contract_id month year deadline_date payment_date])
      return permitted unless permitted.key?(:contract_id)

      scoped_contract = @active_lead_provider.contracts.find_by(id: permitted[:contract_id])
      permitted.merge(contract_id: scoped_contract&.id)
    end

    def statement_path(statement)
      admin_contract_period_active_lead_provider_statement_path(@active_lead_provider.contract_period, @active_lead_provider, statement)
    end

    def statements_path
      admin_contract_period_active_lead_provider_statements_path(@active_lead_provider.contract_period, @active_lead_provider)
    end
  end
end
