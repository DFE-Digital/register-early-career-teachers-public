module Admin
  module Teachers
    class FailedTRNMergesController < AdminController
      layout "full"

      def index
        teachers = Teacher.trs_response_permanent_redirect.order(:id)
        @pagy, paginated_teachers = pagy(teachers)

        redirected_teachers_by_trn =
          Teacher
            .where(trn: paginated_teachers.filter_map(&:trs_redirected_to))
            .index_by(&:trn)

        @teacher_rows = paginated_teachers.map do |teacher|
          {
            teacher:,
            redirected_teacher: redirected_teachers_by_trn[teacher.trs_redirected_to]
          }
        end
      end
    end
  end
end
