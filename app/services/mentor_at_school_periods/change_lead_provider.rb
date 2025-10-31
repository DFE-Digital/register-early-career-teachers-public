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
  end
end
