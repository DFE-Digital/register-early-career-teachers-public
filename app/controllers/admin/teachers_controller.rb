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
      @teacher = TeacherPresenter.new(Teacher.find_by(trn: params[:id]))
    end
  end
end
