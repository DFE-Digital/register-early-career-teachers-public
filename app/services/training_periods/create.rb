module TrainingPeriods
  class Create
    def initialize(period:, started_on:, training_programme:, school_partnership: nil, expression_of_interest: nil)
      @period = period
      @started_on = started_on
      @school_partnership = school_partnership
      @expression_of_interest = expression_of_interest
      @training_programme = training_programme
    end

    def self.school_led(period:, started_on:)
      new(period:, started_on:, training_programme: 'school_led')
    end

    def self.provider_led(period:, started_on:, school_partnership:, expression_of_interest:)
      new(period:, started_on:, school_partnership:, expression_of_interest:, training_programme: 'provider_led')
    end

    def call
      ::TrainingPeriod.create!(
        period_type_key => @period,
        started_on: @started_on,
        school_partnership: @school_partnership,
        expression_of_interest: @expression_of_interest,
        training_programme: @training_programme
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
