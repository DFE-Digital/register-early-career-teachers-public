module Admin
  module Teachers
    class ExtensionsController < AdminController
      before_action :teacher, only: %i[index new create]
      before_action :set_extension, only: %i[edit update confirm_delete destroy]

      def index
      end

      def new
        @extension = @teacher.induction_extensions.build
      end

      def create
        if manage_extensions.create_or_update!(number_of_terms: extension_params[:number_of_terms])
          redirect_to admin_teacher_path(@teacher), notice: "Extension was successfully added."
        else
          @extension = manage_extensions.induction_extension
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if manage_extensions.create_or_update!(id: params[:id], number_of_terms: extension_params[:number_of_terms])
          redirect_to admin_teacher_path(@teacher), notice: "Extension was successfully updated."
        else
          @extension = manage_extensions.induction_extension
          render :edit, status: :unprocessable_entity
        end
      end

      def confirm_delete
      end

      def destroy
        if manage_extensions.delete!(id: params[:id])
          redirect_to admin_teacher_path(@teacher), notice: "Extension was successfully deleted."
        else
          redirect_to admin_teacher_extensions_path(@teacher), alert: "Failed to delete extension."
        end
      end

    private

      def manage_extensions
        @manage_extensions ||= ::InductionExtensions::Manage.new(
          author: current_user,
          appropriate_body: nil,
          teacher: @teacher
        )
      end

      def teacher
        @teacher ||= Teacher.find(params[:teacher_id])
      end

      def set_extension
        @teacher = Teacher.find(params[:teacher_id])
        @extension = @teacher.induction_extensions.find(params[:id])
      end

      def extension_params
        params.require(:induction_extension).permit(:number_of_terms)
      end
    end
  end
end
