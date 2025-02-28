module Teachers
  class DetailsComponent < ViewComponent::Base
    renders_one :personal_details, -> {
      Teachers::Details::PersonalDetailsComponent.new(teacher:)
    }

    renders_one :itt_details, -> {
      Teachers::Details::ITTDetailsComponent.new(teacher:)
    }

    renders_one :induction_summary, -> {
      Teachers::Details::InductionSummaryComponent.new(teacher:)
    }

    renders_one :current_induction_period, ->(enable_release: nil, enable_edit: nil) {
      Teachers::Details::CurrentInductionPeriodComponent.new(
        teacher:,
        enable_release:,
        enable_edit:
      )
    }

    renders_one :past_induction_periods, ->(enable_edit: nil) {
      Teachers::Details::PastInductionPeriodsComponent.new(teacher:, enable_edit:)
    }

    attr_reader :teacher, :mode

    def initialize(mode:, teacher:)
      fail unless mode.in?(%i[admin appropriate_body school])

      @teacher = teacher
      @mode = mode
    end
  end
end
