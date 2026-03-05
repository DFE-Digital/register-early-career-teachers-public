module Admin
  module Finance
    class SearchDeclarationsController < Admin::Finance::BaseController
      def show
        declaration_api_id = params[:declaration_api_id]

        return if declaration_api_id.blank?

        declaration = Admin::Finance::Declarations::Search.from_api_id(raw_query: declaration_api_id)

        if declaration.nil?
          @no_results_found = true
          return
        end

        teacher = declaration.ect_teacher || declaration.mentor_teacher
        raise "Declaration #{declaration.id} has no associated teacher" if teacher.blank?

        redirect_to admin_teacher_declarations_path(teacher, anchor: "declarations")
      end
    end
  end
end
