module ECTAtSchoolPeriods
  class IncorrectTrainingProgrammeError < StandardError; end
  class NoTrainingPeriodError < StandardError; end

  class SwitchTraining
    include TrainingPeriodSources

    def self.to_school_led(...) = new(...).to_school_led
    def self.to_provider_led(...) = new(...).to_provider_led

    def initialize(ect_at_school_period, author:, lead_provider: nil)
      raise ArgumentError, "an `ECTAtSchoolPeriod` must be provided" unless
        ect_at_school_period.is_a?(ECTAtSchoolPeriod)

      @ect_at_school_period = ect_at_school_period
      @training_period = ect_at_school_period.current_or_next_training_period

      raise NoTrainingPeriodError unless @training_period

      @school = @ect_at_school_period.school
      @lead_provider = lead_provider.presence || @training_period.lead_provider
      @author = author
    end

    def to_school_led
      raise IncorrectTrainingProgrammeError if
        @ect_at_school_period.school_led_training_programme?

      ActiveRecord::Base.transaction do
        finish_or_destroy_existing_training_period!
        create_school_led_training_period!
        record_training_period_switched_to_school_led_event!
      end
    end

    def to_provider_led
      raise IncorrectTrainingProgrammeError if
        @ect_at_school_period.provider_led_training_programme?

      ActiveRecord::Base.transaction do
        finish_training_period!
        create_provider_led_training_period!
        record_training_period_switched_to_provider_led_event!
      end
    end

  private

    attr_reader :school, :lead_provider

    def finish_or_destroy_existing_training_period!
      if @training_period.school_partnership.present?
        finish_training_period!
      else
        @training_period.destroy!
      end
    end

    def finish_training_period!
      TrainingPeriods::Finish.ect_training(
        training_period: @training_period,
        ect_at_school_period: @ect_at_school_period,
        finished_on:,
        author: @author
      ).finish!
    end

    def create_school_led_training_period!
      @new_training_period = TrainingPeriods::Create.school_led(
        period: @ect_at_school_period,
        started_on:
      ).call
    end

    def create_provider_led_training_period!
      @new_training_period = TrainingPeriods::Create.provider_led(
        period: @ect_at_school_period,
        started_on:,
        school_partnership: earliest_matching_school_partnership,
        expression_of_interest:
      ).call
    end

    def record_training_period_switched_to_school_led_event!
      Events::Record.record_teacher_switches_to_school_led_training!(
        author: @author,
        ect_at_school_period: @ect_at_school_period,
        teacher: @ect_at_school_period.teacher,
        training_period: @new_training_period,
        school:,
        happened_at: Time.current
      )
    end

    def record_training_period_switched_to_provider_led_event!
      Events::Record.record_teacher_switches_to_provider_led_training!(
        author: @author,
        ect_at_school_period: @ect_at_school_period,
        teacher: @ect_at_school_period.teacher,
        training_period: @new_training_period,
        school:,
        happened_at: Time.current
      )
    end

    def started_on = Date.current
    def finished_on = Date.current
  end
end
