module Admin
  module Teachers
    class FailedTRNMergesController < AdminController
      layout "full"

      def index
        failed_trn_merges = Teacher.trs_response_permanent_redirect.preload(:redirected_teacher)

        @pagy, @teachers = pagy(failed_trn_merges)
      end
    end
  end
end
