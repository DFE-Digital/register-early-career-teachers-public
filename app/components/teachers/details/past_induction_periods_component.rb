module Teachers
  module Details
    class PastInductionPeriodsComponent < ViewComponent::Base
      attr_reader :teacher, :induction, :enable_edit

      def initialize(teacher:, enable_edit: false)
        @teacher = teacher
        @induction = Teachers::Induction.new(teacher)
        @enable_edit = enable_edit
      end

      def render?
        past_periods.any?
      end

    private

      def past_periods
        @past_periods ||= induction.past_induction_periods
      end

      def can_edit?(period)
        enable_edit && period.outcome.blank?
      end

      def edit_link(period)
        return unless can_edit?(period)

        helpers.govuk_link_to('Edit', helpers.edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: period.id), no_visited_state: true)
      end
    end
  end
end
