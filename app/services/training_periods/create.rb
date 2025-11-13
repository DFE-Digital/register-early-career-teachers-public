module TrainingPeriods
  class Create
    def initialize(period:, started_on:, training_programme:, school_partnership: nil, expression_of_interest: nil, finished_on: nil, schedule: nil, author: nil)
      @period = period
      @started_on = started_on
      @school_partnership = school_partnership
      @expression_of_interest = expression_of_interest
      @training_programme = training_programme
      @finished_on = finished_on
      @schedule = schedule
      @author = author
    end

    def self.school_led(period:, started_on:)
      new(period:, started_on:, training_programme: 'school_led')
    end

    def self.provider_led(period:, started_on:, school_partnership:, expression_of_interest:, finished_on: nil, schedule: nil, author: nil)
      new(period:, started_on:, school_partnership:, expression_of_interest:, training_programme: 'provider_led', finished_on:, schedule:, author:)
    end

    def call
      @new_training_period = create!
      record_event!
      @new_training_period
    end

  private

    def period_type_key
      case @period
      when ::ECTAtSchoolPeriod then :ect_at_school_period
      when ::MentorAtSchoolPeriod then :mentor_at_school_period
      else raise ArgumentError, "Unsupported period type: #{@period.class}"
      end
    end

    def create!
      ::TrainingPeriod.create!(
        period_type_key => @period,
        started_on: @started_on,
        school_partnership: @school_partnership,
        expression_of_interest: @expression_of_interest,
        training_programme: @training_programme,
        finished_on: @finished_on,
        schedule: @schedule
      )
    end

    def record_event!
      return if @training_programme == 'school_led'
      return unless @new_training_period.schedule

      Events::Record.record_teacher_schedule_assigned_to_training_period!(
        training_period: @new_training_period,
        teacher: @period.teacher,
        schedule: @new_training_period.schedule,
        author: @author,
        happened_at: Time.current
      )
    end
  end
end
