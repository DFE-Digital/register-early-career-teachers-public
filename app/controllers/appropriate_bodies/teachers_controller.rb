module AppropriateBodies
  class TeachersController < AppropriateBodiesController
    layout "full", only: :index

    def index
      @status = params[:status] || 'open'
      @pagy, @teachers = pagy(search_teachers, limit: 50)
    end

    def show
      @teacher = AppropriateBodies::ECTs.new(@appropriate_body).current_or_completed_while_at_appropriate_body.find_by!(id: params[:id])
    end

  private

    def search_teachers
      ::Teachers::Search.new(
        query_string: params[:q],
        appropriate_bodies: @appropriate_body,
        status: @status
      )
      .search
      .includes(
        :induction_periods,
        :first_induction_period,
        :last_induction_period
      )
    end
  end
end
