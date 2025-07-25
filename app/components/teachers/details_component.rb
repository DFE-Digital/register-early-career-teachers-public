module Teachers
  class DetailsComponent < ViewComponent::Base
    MODES = %i[admin appropriate_body school].freeze

    renders_one :personal_details, -> {
      Teachers::Details::PersonalDetailsComponent.new(teacher:)
    }

    renders_one :itt_details, -> {
      Teachers::Details::ITTDetailsComponent.new(teacher:)
    }

    renders_one :induction_summary, -> {
      if admin_mode?
        Teachers::Details::AdminInductionSummaryComponent.new(teacher:)
      else
        Teachers::Details::AppropriateBodyInductionSummaryComponent.new(teacher:)
      end
    }

    renders_one :current_induction_period, ->(enable_release: false, enable_edit: false, enable_delete: false) {
      Teachers::Details::CurrentInductionPeriodComponent.new(mode:, teacher:, enable_release:, enable_edit:, enable_delete:)
    }

    renders_one :past_induction_periods, ->(enable_edit: false) {
      Teachers::Details::PastInductionPeriodsComponent.new(teacher:, enable_edit:)
    }

    renders_one :induction_outcome_actions, -> {
      Teachers::Details::InductionOutcomeActionsComponent.new(mode:, teacher:)
    }

    attr_reader :mode, :teacher

    def initialize(mode:, teacher:)
      fail unless mode.in?(MODES)

      @mode = mode
      @teacher = teacher
    end

  private

    def admin_mode?
      mode == :admin
    end
  end
end
