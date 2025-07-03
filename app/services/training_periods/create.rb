module TrainingPeriods
  class Create
    def initialize(period:, started_on:, school_partnership:, expression_of_interest:)
      @period = period
      @started_on = started_on
      @school_partnership = school_partnership
      @expression_of_interest = expression_of_interest
    end

    def call
      ::TrainingPeriod.create!(
        period_type_key => @period,
        started_on: @started_on,
        school_partnership: @school_partnership,
        expression_of_interest: @expression_of_interest
      )
    end

  private

    def period_type_key
      case @period
      when ::ECTAtSchoolPeriod then :ect_at_school_period
      when ::MentorAtSchoolPeriod then :mentor_at_school_period
      else raise ArgumentError, "Unsupported period type: #{@period.class}"
      end
    end
  end
end
