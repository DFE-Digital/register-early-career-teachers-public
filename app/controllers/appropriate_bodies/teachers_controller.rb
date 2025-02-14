module AppropriateBodies
  class TeachersController < AppropriateBodiesController
    layout "full", only: :index

    def index
      @pagy, @teachers = pagy(
        ::Teachers::Search.new(
          query_string: params[:q],
          appropriate_body: @appropriate_body
        ).search
      )
      @claimed_inductions_count = AppropriateBodies::ECTs.new(@appropriate_body).current.count
    end

    def show
      @teacher = AppropriateBodies::ECTs.new(@appropriate_body).current.find_by!(id: params[:id])
    end
  end
end
