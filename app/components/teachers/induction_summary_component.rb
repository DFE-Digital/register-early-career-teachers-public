module Teachers
  class InductionSummaryComponent < ViewComponent::Base
    attr_reader :teacher, :induction

    def initialize(teacher:)
      @teacher = teacher
      @induction = Teachers::Induction.new(teacher)
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
      helpers.govuk_tag(text: "placeholder", colour: %w[grey green red purple orange yellow].sample)
    end

    def extension_view_link
      helpers.govuk_link_to("View", helpers.ab_teacher_extensions_path(teacher), no_visited_state: true)
    end
  end
end
