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

    def induction_period_programme(period)
      if Rails.application.config.enable_bulk_claim
        helpers.training_programme_name(period.training_programme)
      else
        ::INDUCTION_PROGRAMMES[period.induction_programme.to_sym]
      end
    end

    delegate :govuk_link_to, to: :helpers

    def actions_for(period)
      return [] unless enable_edit

      [
        govuk_link_to(
          'Edit',
          helpers.edit_admin_teacher_induction_period_path(teacher, period),
          no_visited_state: true
        ),
        govuk_link_to(
          'Delete',
          helpers.confirm_delete_admin_teacher_induction_period_path(teacher, period),
          no_visited_state: true
        )
      ]
    end
  end
end
