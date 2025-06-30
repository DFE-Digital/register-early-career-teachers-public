module Admin::Finance
  class AdjustmentsController < AdminController
    before_action :set_statement
    before_action :redirect_if_adjustment_not_editable
    before_action :set_adjustment, only: %i[edit update delete destroy]

    def new
      @adjustment = @statement.adjustments.new
    end

    def create
      @adjustment = @statement.adjustments.new(adjustment_params)

      if @adjustment.save
        Events::Record.record_statement_adjustment_added_event!(author: current_user, statement_adjustment: @adjustment)
        redirect_to statement_path, alert: "Adjustment added"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @adjustment.update(adjustment_params)
        Events::Record.record_statement_adjustment_updated_event!(author: current_user, statement_adjustment: @adjustment)
        redirect_to statement_path, alert: "Adjustment changed"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def delete
    end

    def destroy
      @adjustment.destroy!
      Events::Record.record_statement_adjustment_deleted_event!(author: current_user, statement_adjustment: @adjustment)
      redirect_to statement_path, alert: "Adjustment removed"
    end

  private

    def adjustment_params
      params.permit(
        statement_adjustment: %i[payment_type amount form_step]
      )[:statement_adjustment] || {}
    end

    def set_statement
      @statement = Statement.find(params[:finance_statement_id])
    end

    def set_adjustment
      @adjustment = @statement.adjustments.find(params[:id])
    end

    def redirect_if_adjustment_not_editable
      return if @statement.adjustment_editable?

      redirect_to statement_path
    end

    def statement_path
      admin_finance_statement_path(@statement)
    end

    helper_method :statement_path
  end
end
