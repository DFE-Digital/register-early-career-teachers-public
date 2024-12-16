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
  end
end
