module Admin
  module Finance
    class VoidsController < Admin::Finance::BaseController
      layout "full"

      before_action :set_declaration
      before_action :set_teacher
      before_action :set_void_declaration_form

      def new
      end

      def create
        if @void_declaration_form.void!
          flash[:alert] = "Declaration voided"
          redirect_to admin_teacher_declarations_path(@teacher)
        else
          render :new, status: :unprocessable_content
        end
      end

    private

      def set_declaration
        @declaration = Declaration.find(params[:declaration_id])
      end

      def set_teacher
        @teacher = @declaration.teacher
      end

      def set_void_declaration_form
        @void_declaration_form = VoidDeclarationForm.new(
          declaration: @declaration,
          author: current_user,
          **void_declaration_form_params
        )
      end

      def void_declaration_form_params
        return {} unless params.key?(:admin_finance_void_declaration_form)

        params.expect(admin_finance_void_declaration_form: [:confirmed])
      end
    end
  end
end
