module AppropriateBodies
  class TeachersController < AppropriateBodiesController
    layout "full", only: :index

    def index
      @pagy, @teachers = pagy(
        ::Teachers::Search.new(
          query_string: params[:q],
          appropriate_bodies: @appropriate_body,
        ).search,
        size: 50
      )

      @claimed_inductions_count = AppropriateBodies::ECTs.new(@appropriate_body).current_or_completed_while_at_appropriate_body.count
    end

    def show
      @teacher = AppropriateBodies::ECTs.new(@appropriate_body).current_or_completed_while_at_appropriate_body.find_by!(id: params[:id])
    end
  end
end
