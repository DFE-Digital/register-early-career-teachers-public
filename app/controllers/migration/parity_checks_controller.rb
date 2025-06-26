class Migration::ParityChecksController < ::AdminController
  before_action :load_endpoints, only: %i[new create]

  def new
    @runner = ParityCheck::Runner.new
  end

  def create
    @runner = ParityCheck::Runner.new(runner_params)
    if @runner.valid?
      @runner.run!
      flash[:notice] = "Parity check has been started."
      redirect_to new_migration_parity_check_path
    else
      render :new
    end
  end

private

  def load_endpoints
    @endpoints = ParityCheck::Endpoint.all
  end

  def runner_params
    params.require(:parity_check_runner).permit(:mode, endpoint_ids: [])
  end
end
