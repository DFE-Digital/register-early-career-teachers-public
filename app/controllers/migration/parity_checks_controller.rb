class Migration::ParityChecksController < ::AdminController
  layout "full"

  before_action :load_endpoints, :load_runs, only: %i[new create]

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

private

  def load_endpoints
    @endpoints = ParityCheck::Endpoint.all
  end

  def load_runs
    @in_progress_run = ParityCheck::Run.in_progress.first
    @pending_runs = ParityCheck::Run.pending
  end

  def runner_params
    params.require(:parity_check_runner).permit(:mode, endpoint_ids: [])
  end
end
