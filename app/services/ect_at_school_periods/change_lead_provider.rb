module ECTAtSchoolPeriods
  class ChangeLeadProvider
    class SchoolLedTrainingProgrammeError < StandardError; end

    include Teachers::LeadProviderChanger

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

    def track_payments_frozen_year!
      return unless confirmed_training_reassignment_required?

      teacher.update!(ect_payments_frozen_year: previous_contract_period.year)
    end
  end
end
