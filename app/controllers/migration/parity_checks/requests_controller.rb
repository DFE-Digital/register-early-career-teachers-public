module Migration::ParityChecks
  class RequestsController < ::AdminController
    layout "full"

    def show
      @request = ParityCheck::Run.completed.find(params[:parity_check_run_id]).requests.find(params[:id])
      @pagy, @responses = pagy(@request.responses.ordered_by_page)

      @multiple_pages = @responses.any?(&:page)
      @breadcrumbs = {
        "Run a parity check" => new_migration_parity_check_path,
        "Completed parity checks" => completed_migration_parity_checks_path,
        "Parity check run ##{@request.run_id}" => migration_parity_check_path(@request.run),
      }
    end
  end
end
