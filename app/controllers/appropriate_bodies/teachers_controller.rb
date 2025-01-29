module AppropriateBodies
  class TeachersController < AppropriateBodiesController
    layout "full", only: :index

    def index
      @teachers = ::Teachers::Search.new(
        query_string: params[:q],
        appropriate_body: @appropriate_body
      ).search
    end

    def show
      @teacher = AppropriateBodies::CurrentTeachers.new(@appropriate_body).current.find_by!(id: params[:id])
    end
  end
end
