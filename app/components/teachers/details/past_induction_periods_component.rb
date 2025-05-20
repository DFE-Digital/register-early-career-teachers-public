module Teachers::Details
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

    def edit_link(period)
      return unless enable_edit

      helpers.govuk_link_to('Edit', helpers.edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: period.id), no_visited_state: true)
    end

    def delete_link(period)
      return unless enable_edit

      helpers.govuk_link_to('Delete', helpers.confirm_delete_admin_teacher_induction_period_path(teacher_id: teacher.id, id: period.id), method: :get, class: 'govuk-link--destructive', no_visited_state: true)
    end
  end
end
