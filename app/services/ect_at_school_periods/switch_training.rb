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
        if date_of_transition.future? || @training_period.school_partnership.blank?
          @training_period.destroy!
        else
          finish_training_period!
        end

        create_school_led_training_period!
      end
    end

    def to_provider_led
      raise IncorrectTrainingProgrammeError if
        @ect_at_school_period.provider_led_training_programme?

      ActiveRecord::Base.transaction do
        if date_of_transition.future?
          @training_period.destroy!
        else
          finish_training_period!
        end

        create_provider_led_training_period!
      end
    end

  private

    attr_reader :school, :lead_provider

    def date_of_transition = [@ect_at_school_period.started_on, Date.current].max

    def finish_training_period!
      TrainingPeriods::Finish.ect_training(
        training_period: @training_period,
        ect_at_school_period: @ect_at_school_period,
        finished_on: Date.current,
        author: @author
      ).finish!
    end

    def create_school_led_training_period!
      TrainingPeriods::Create.school_led(
        period: @ect_at_school_period,
        started_on: date_of_transition
      ).call
    end

    def create_provider_led_training_period!
      TrainingPeriods::Create.provider_led(
        period: @ect_at_school_period,
        started_on: date_of_transition,
        school_partnership: earliest_matching_school_partnership,
        expression_of_interest:,
        author: @author
      ).call
    end

    def started_on = date_of_transition
  end
end
