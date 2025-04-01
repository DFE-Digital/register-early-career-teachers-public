module AppropriateBodies
  module Teachers
    class ExtensionsController < AppropriateBodiesController
      before_action :teacher, only: :index

      def index
      end

      def new
        @extension = teacher.induction_extensions.build
      end

      def create
        if manage_extensions.create_or_update!(number_of_terms: extension_params[:number_of_terms])
          redirect_to ab_teacher_path(teacher), alert: "Extension was successfully added."
        else
          @extension = manage_extensions.induction_extension
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @extension = teacher.induction_extensions.find(params[:id])
      end

      def update
        if manage_extensions.create_or_update!(id: params[:id], number_of_terms: extension_params[:number_of_terms])
          redirect_to ab_teacher_path(teacher), alert: "Extension was successfully updated."
        else
          @extension = manage_extensions.induction_extension
          render :edit, status: :unprocessable_entity
        end
      end

    private

      def manage_extensions
        @manage_extensions ||= ::InductionExtensions::Manage.new(
          author: current_user,
          appropriate_body: @appropriate_body,
          teacher:
        )
      end

      def teacher
        @teacher ||= AppropriateBodies::ECTs.new(@appropriate_body).current.find_by!(id: params[:teacher_id])
      end

      def extension_params
        params.require(:induction_extension).permit(:number_of_terms)
      end
    end
  end
end
