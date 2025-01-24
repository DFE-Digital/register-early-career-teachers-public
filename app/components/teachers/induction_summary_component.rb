module Teachers
  class InductionSummaryComponent < ViewComponent::Base
    attr_reader :teacher, :induction, :induction_periods

    def initialize(teacher:)
      @teacher = teacher
      @induction = Teachers::Induction.new(teacher)
      @induction_periods = teacher.induction_periods
    end

    def render?
      induction.has_induction_periods?
    end

    def extensions_action_text
      (induction_extensions.extended?) ? 'View' : 'Add'
    end

  private

    def induction_extensions
      @induction_extensions ||= Teachers::InductionExtensions.new(teacher)
    end

    def status_tag
      helpers.govuk_tag(**Teachers::InductionStatus.new(teacher:, induction_periods:, trs_induction_status:).status_tag_kwargs)
    end

    def extension_view_link
      helpers.govuk_link_to("View", helpers.ab_teacher_extensions_path(teacher), no_visited_state: true)
    end

    def trs_induction_status
      teacher.trs_induction_status
    end
  end
end
