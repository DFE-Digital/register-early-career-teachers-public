module Teachers
  class ChangeSchedule
    attr_reader :lead_provider, :teacher, :training_period, :schedule, :school_partnership, :author

    def initialize(author:, lead_provider:, teacher:, training_period:, schedule:, school_partnership:)
      @lead_provider = lead_provider
      @teacher = teacher
      @training_period = training_period
      @schedule = schedule
      @school_partnership = school_partnership
      @author = author
    end

    def change_schedule
      ActiveRecord::Base.transaction do
        finished_on = determine_finished_on

        track_payments_frozen_year!
        finish_training_period!
        new_training_period = create_new_training_period!(finished_on:)
        record_change_schedule_event!(original_training_period: training_period, new_training_period:)
      end

      teacher
    end

  private

    # Determine the correct finished_on date for the new training period.
    # In order of priority, we will take:
    #
    # 1. The finished_on of the current training period (if today or later)
    # 2. The finished_on of the school period (if today or later)
    # 3. nil (meaning the training period we are closing is ongoing)
    def determine_finished_on
      [
        training_period.finished_on,
        training_period.trainee.finished_on
      ].compact.reject(&:past?).min
    end

    def finish_training_period!
      finished_on = [training_period.finished_on, Time.zone.today].compact.min

      if training_period.for_ect?
        TrainingPeriods::Finish.ect_training(
          author:,
          training_period:,
          ect_at_school_period: training_period.trainee,
          finished_on:
        ).finish!
      elsif training_period.for_mentor?
        TrainingPeriods::Finish.mentor_training(
          author:,
          training_period:,
          mentor_at_school_period: training_period.trainee,
          finished_on:
        ).finish!
      end
    end

    def create_new_training_period!(finished_on:)
      TrainingPeriods::Create.provider_led(
        period: training_period.trainee,
        started_on: Time.zone.today,
        finished_on:,
        school_partnership:,
        expression_of_interest: nil,
        schedule:,
        author:
      ).call
    end

    def record_change_schedule_event!(original_training_period:, new_training_period:)
      return unless original_training_period.saved_changes?

      Events::Record.record_teacher_schedule_changed_event!(
        author:,
        original_training_period:,
        new_training_period:,
        teacher:,
        lead_provider:
      )
    end

    def current_contract_period
      @current_contract_period ||= training_period.schedule.contract_period
    end

    def new_contract_period
      @new_contract_period ||= schedule.contract_period
    end

    def track_payments_frozen_year!
      if changing_from_payments_frozen_contract_period?
        set_payments_frozen_year(year: current_contract_period.year)
      elsif changing_to_payments_frozen_contract_period?
        set_payments_frozen_year(year: nil)
      end
    end

    def set_payments_frozen_year(year:)
      if training_period.for_ect?
        teacher.update!(ect_payments_frozen_year: year)
      else
        teacher.update!(mentor_payments_frozen_year: year)
      end
    end

    def changing_contract_period?
      current_contract_period != new_contract_period
    end

    def changing_to_payments_frozen_contract_period?
      changing_contract_period? && new_contract_period.payments_frozen?
    end

    def changing_from_payments_frozen_contract_period?
      changing_contract_period? && current_contract_period.payments_frozen?
    end
  end
end
