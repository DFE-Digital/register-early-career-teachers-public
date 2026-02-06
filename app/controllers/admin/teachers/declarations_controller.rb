module Admin
  module Teachers
    class DeclarationsController < AdminController
      layout "full"

      def index
        @teacher = Teacher.find(params[:teacher_id])
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :declarations)
        @breadcrumbs = teacher_breadcrumbs

        @ect_declarations = @teacher.ect_declarations
          .includes(training_period: %i[lead_provider delivery_partner])
          .order(declaration_date: :asc)
        @mentor_declarations = @teacher.mentor_declarations
          .includes(training_period: %i[lead_provider delivery_partner])
          .order(declaration_date: :asc)
      end

    private

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          ::Teachers::Name.new(@teacher).full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]),
          "Declarations" => nil
        }
      end
    end
  end
end
