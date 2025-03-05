module Admin
  class TeachersController < AdminController
    layout "full"

    def index
      @appropriate_bodies = AppropriateBody.order(:name)
      @pagy, @teachers = pagy(
        Teachers::Search.new(
          query_string: params[:q]
        ).search
      )
    end

    def show
      @page = params[:page] || 1
      teacher = Teacher.find_by(id: params[:id])
      @teacher = TeacherPresenter.new(teacher)
      @events = teacher.events.latest_first
    end
  end
end
