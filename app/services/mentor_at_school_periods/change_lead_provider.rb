module MentorAtSchoolPeriods
  class ChangeLeadProvider
    include Teachers::SwitchLeadProviderHelper

  private

    def mentor_at_school_period
      period
    end

    def finish_training_period!
      return if training_period.blank?

      TrainingPeriods::Finish.mentor_training(
        training_period:,
        mentor_at_school_period:,
        finished_on: Date.current,
        author:
      ).finish!
    end

    def record_lead_provider_updated_event!
      ::Events::Record.record_mentor_lead_provider_updated_event!(
        old_lead_provider_name: old_lead_provider.name,
        new_lead_provider_name: new_lead_provider.name,
        author:,
        mentor_at_school_period:,
        school:,
        teacher:,
        happened_at: Time.current
      )
    end
  end
end
