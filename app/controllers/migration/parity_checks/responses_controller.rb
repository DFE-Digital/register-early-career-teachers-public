module Migration::ParityChecks
  class ResponsesController < ::AdminController
    layout "full"

    def show
      @run = ParityCheck::Run.completed.find(params[:parity_check_run_id])
      @response = @run.responses.different.find(params[:id])
      @request = @response.request
      @breadcrumbs = {
        "Run a parity check" => new_migration_parity_check_path,
        "Completed parity checks" => completed_migration_parity_checks_path,
        "Parity check run ##{@run.id}" => migration_parity_check_path(@run),
        @request.description => migration_parity_check_request_path(@run, @request),
      }
    end
  end
end
