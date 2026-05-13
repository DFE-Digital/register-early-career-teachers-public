module Admin
  module Teachers
    class TrainingsController < AdminController
      layout "full"

      def show
        @teacher = TeacherPresenter.new(Teacher.find(params[:teacher_id]))
        @navigation_items = helpers.admin_teacher_navigation_items(@teacher, :training)
        @breadcrumbs = teacher_breadcrumbs
        @ect_at_school_periods = @teacher.ect_at_school_periods
        @ect_training_periods = @teacher.ect_training_periods
          .includes(:active_lead_provider, :expression_of_interest, ect_at_school_period: :teacher)
          .latest_first
        @mentor_training_periods = @teacher.mentor_training_periods
          .includes(:active_lead_provider, :expression_of_interest, mentor_at_school_period: :teacher)
          .latest_first
        @latest_training_period_ids_with_api_response = latest_training_period_ids_with_api_response
      end

    private

      def latest_training_period_ids_with_api_response
        [@ect_training_periods, @mentor_training_periods].flat_map do |training_periods|
          training_periods
            .select(&:provider_led_training_programme?)
            .group_by { |training_period| lead_provider_id_for(training_period) }
            .map { |_lead_provider_id, training_periods| training_periods.first.id }
        end
      end

      def lead_provider_id_for(training_period)
        training_period.active_lead_provider&.lead_provider_id ||
          training_period.expression_of_interest&.lead_provider_id
      end

      def teacher_breadcrumbs
        {
          "Teachers" => admin_teachers_path(page: params[:page], q: params[:q]),
          @teacher.full_name => admin_teacher_path(@teacher, page: params[:page], q: params[:q]),
          "Training" => nil
        }
      end
    end
  end
end
