module TrainingPeriods
  class ChangePartnership
    attr_reader :training_period, :school_partnership, :author

    def initialize(training_period:, school_partnership:, author:)
      @training_period = training_period
      @school_partnership = school_partnership
      @author = author
    end

    def call
      raise ArgumentError, "training_period is required" if training_period.blank?
      raise ArgumentError, "school_partnership is required" if school_partnership.blank?

      training_period.transaction do
        if training_period.partnership_change_requires_replacement?
          replace_training_period!
        else
          update_training_period_in_place!
        end
      end
    end

  private

    def update_training_period_in_place!
      training_period.update!(
        school_partnership:
      )

      record_partnership_assignment_event!(training_period)
    end

    def replace_training_period!
      finish_current_training_period!
      new_training_period = create_replacement_training_period!
      record_partnership_assignment_event!(new_training_period)
    end

    def finish_current_training_period!
      if training_period.for_ect?
        TrainingPeriods::Finish.ect_training(
          training_period:,
          ect_at_school_period: training_period.ect_at_school_period,
          finished_on: Date.current,
          author:
        ).finish!
      else
        TrainingPeriods::Finish.mentor_training(
          training_period:,
          mentor_at_school_period: training_period.mentor_at_school_period,
          finished_on: Date.current,
          author:
        ).finish!
      end
    end

    def create_replacement_training_period!
      TrainingPeriods::Create.provider_led(
        period: training_period.at_school_period,
        started_on: Date.current,
        school_partnership:,
        expression_of_interest: nil,
        schedule: training_period.schedule,
        author:
      ).call
    end

    def record_partnership_assignment_event!(period)
      Events::Record.record_training_period_assigned_to_school_partnership_event!(
        author:,
        training_period: period,
        ect_at_school_period: period.ect_at_school_period,
        mentor_at_school_period: period.mentor_at_school_period,
        teacher: period.teacher,
        school_partnership:,
        lead_provider: school_partnership.lead_provider,
        delivery_partner: school_partnership.delivery_partner,
        school: school_partnership.school
      )
    end
  end
end
