module ECTAtSchoolPeriods
  class SwitchLeadProvider
    class SchoolLedTrainingProgrammeError < StandardError; end

    include TrainingPeriodSources

    def self.switch(...) = new(...).switch

    def initialize(ect_at_school_period, to:, from:, author:)
      @ect_at_school_period = ect_at_school_period
      @selected_lead_provider = to
      @current_lead_provider = from
      @author = author
    end

    def switch
      raise SchoolLedTrainingProgrammeError if training_period&.school_led_training_programme?

      ActiveRecord::Base.transaction do
        if date_of_transition.future? || training_period.school_partnership.blank?
          training_period.destroy!
        else
          finish_training_period!
        end

        create_training_period!
        record_lead_provider_updated_event!
      end
    end

  private

    attr_reader :ect_at_school_period,
                :current_lead_provider,
                :selected_lead_provider,
                :author

    def finish_training_period!
      TrainingPeriods::Finish.ect_training(
        training_period:,
        ect_at_school_period:,
        finished_on: Date.current,
        author:
      ).finish!
    end

    def create_training_period!
      TrainingPeriods::Create.provider_led(
        period: ect_at_school_period,
        started_on: date_of_transition,
        school_partnership: earliest_matching_school_partnership,
        expression_of_interest:
      ).call
    end

    def record_lead_provider_updated_event!
      Events::Record.record_teacher_training_lead_provider_updated_event!(
        old_lead_provider_name: current_lead_provider.name,
        new_lead_provider_name: selected_lead_provider.name,
        author:,
        ect_at_school_period:,
        school: ect_at_school_period.school,
        teacher: ect_at_school_period.teacher,
        happened_at: Time.current
      )
    end

    def date_of_transition = [ect_at_school_period.started_on, Date.current].max
    def training_period = ect_at_school_period.current_or_next_training_period
    def school = ect_at_school_period.school
    def lead_provider = selected_lead_provider
    def started_on = date_of_transition
  end
end
