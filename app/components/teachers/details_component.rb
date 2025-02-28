module Teachers
  class DetailsComponent < ViewComponent::Base
    renders_one :personal_details, -> do
      Teachers::Details::PersonalDetailsComponent.new(teacher:)
    end

    renders_one :itt_details, -> do
      Teachers::Details::ITTDetailsComponent.new(teacher:)
    end

    renders_one :induction_summary, -> do
      Teachers::Details::InductionSummaryComponent.new(teacher:)
    end

    renders_one :current_induction_period, -> do
      Teachers::Details::CurrentInductionPeriodComponent.new(teacher:)
    end

    renders_one :past_induction_periods, -> do
      Teachers::Details::PastInductionPeriodsComponent.new(teacher:)
    end

    attr_reader :teacher

    def initialize(mode:, teacher:)
      fail unless mode.in?(%i[admin appropriate_body school])

      @teacher = teacher
    end
  end
end
