class Migration::ParityChecksController < ::AdminController
  layout "full"

  before_action :load_endpoints, :load_pending_and_in_progress_runs, :load_lead_providers, only: %i[new create]
  before_action :load_completed_runs, only: %i[new create completed]

  def new
    @runner = ParityCheck::Runner.new
  end

  def create
    @runner = ParityCheck::Runner.new(runner_params)
    if @runner.valid?
      @runner.run!
      flash[:notice] = "Parity check run has been created."
      redirect_to new_migration_parity_check_path
    else
      render :new
    end
  end

  def completed
    @breadcrumbs = {
      "Run a parity check" => new_migration_parity_check_path,
    }
  end

  def show
    @run = ParityCheck::Run.includes(requests: %i[lead_provider responses]).completed.find(params[:run_id])
    @breadcrumbs = {
      "Run a parity check" => new_migration_parity_check_path,
      "Completed parity checks" => completed_migration_parity_checks_path,
    }
  end

private

  def load_endpoints
    @endpoints = ParityCheck::Endpoint.all
  end

  def load_pending_and_in_progress_runs
    @in_progress_run = ParityCheck::Run.in_progress.first
    @pending_runs = ParityCheck::Run.pending
  end

  def load_lead_providers
    @lead_providers = LeadProvider.where.not(ecf_id: nil)
  end

  def load_completed_runs
    completed_runs = ParityCheck::Run.includes(requests: %i[endpoint responses]).completed
    @pagy, @completed_runs = pagy(completed_runs)
  end

  def runner_params
    params.require(:parity_check_runner).permit(:mode, endpoint_ids: [])
  end
end
