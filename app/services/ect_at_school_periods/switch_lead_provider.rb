module ECTAtSchoolPeriods
  class SwitchLeadProvider
    class SchoolLedTrainingProgrammeError < StandardError; end

    include Teachers::SwitchLeadProviderHelper

    def call
      raise SchoolLedTrainingProgrammeError if training_period&.school_led_training_programme?

      super
    end

  private

    def ect_at_school_period
      period
    end

    def finish_training_period!
      TrainingPeriods::Finish.ect_training(
        training_period:,
        ect_at_school_period:,
        finished_on: Date.current,
        author:
      ).finish!
    end

    def record_lead_provider_updated_event!
      Events::Record.record_teacher_training_lead_provider_updated_event!(
        old_lead_provider_name: old_lead_provider.name,
        new_lead_provider_name: new_lead_provider.name,
        author:,
        ect_at_school_period:,
        school:,
        teacher:,
        happened_at: Time.current
      )
    end
  end
end
