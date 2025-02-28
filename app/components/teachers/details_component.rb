module Teachers
  class DetailsComponent < ViewComponent::Base
    renders_one :personal_details, lambda {
      Teachers::Details::PersonalDetailsComponent.new(teacher:)
    }

    renders_one :itt_details, lambda {
      Teachers::Details::ITTDetailsComponent.new(teacher:)
    }

    renders_one :induction_summary, lambda {
      Teachers::Details::InductionSummaryComponent.new(teacher:)
    }

    renders_one :current_induction_period, lambda {
      # Set enable_release based on mode and context
      # Only appropriate bodies can release ECTs, and only in the teacher show context
      enable_release = mode == :appropriate_body && context == :teacher_show
      enable_edit = mode == :admin

      Teachers::Details::CurrentInductionPeriodComponent.new(
        teacher:,
        enable_release:,
        enable_edit:
      )
    }

    renders_one :past_induction_periods, lambda {
      Teachers::Details::PastInductionPeriodsComponent.new(teacher:)
    }

    attr_reader :teacher, :mode, :context

    def initialize(mode:, teacher:, context: :default)
      fail unless mode.in?(%i[admin appropriate_body school])

      @teacher = teacher
      @mode = mode
      @context = context
    end
  end
end
