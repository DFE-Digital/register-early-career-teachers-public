module Teachers
  class PastInductionPeriodsComponent < ViewComponent::Base
    attr_reader :teacher, :induction

    def initialize(teacher:)
      @teacher = teacher
      @induction = Teachers::Induction.new(teacher)
    end

    def render?
      past_periods.any?
    end

  private

    def past_periods
      @past_periods ||= induction.past_induction_periods
    end

    def can_edit?(period)
      period.outcome.blank?
    end

    def edit_link(period)
      helpers.govuk_link_to('Edit', helpers.edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: period.id), no_visited_state: true)
    end
  end
end
