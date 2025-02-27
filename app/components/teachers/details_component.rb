module Teachers
  class DetailsComponent < ViewComponent::Base
    renders_one :personal_details
    renders_one :itt_details
    renders_one :induction_summary
    renders_one :current_induction_period
    renders_one :past_induction_periods

    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end
  end
end
