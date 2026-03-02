module Admin
  module Finance
    class SearchDeclarationsController < Admin::Finance::BaseController
      def show
        raw_query_string = params[:q].to_s

        return if raw_query_string.blank?

        declaration = Admin::Finance::SearchDeclarations::ByAPIId.new(raw_query: raw_query_string).call

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
