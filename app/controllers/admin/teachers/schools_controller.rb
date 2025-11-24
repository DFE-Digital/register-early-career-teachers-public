module Admin
  module Teachers
    class SchoolsController < AdminController
      layout "full"

      def show
        @teacher = TeacherPresenter.new(Teacher.find_by(id: params[:teacher_id]))
        @ect_at_school_periods = @teacher.school_periods_as_an_ect.includes(
          school: :gias_school,
          mentorship_periods: { mentor: :teacher }
        )
        @mentor_at_school_periods = @teacher.school_periods_as_a_mentor.includes(
          school: :gias_school,
          mentorship_periods: { mentee: :teacher }
        )
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :school)
        @breadcrumbs = teacher_breadcrumbs
      end

    private

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          @teacher.full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]),
          "School" => nil
        }
      end
    end
  end
end
