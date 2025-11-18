module Admin
  class TeachersController < AdminController
    layout "full"

    def index
      @appropriate_bodies = AppropriateBody.order(:name)
      @pagy, @teachers = pagy(
        ::Teachers::Search.new(
          query_string: params[:q]
        )
        .search
        .includes(
          :induction_periods,
          :current_appropriate_body
        )
      )
    end

    def show
    end
  end
end
