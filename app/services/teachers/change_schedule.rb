module Teachers
  class ChangeSchedule
    attr_reader :lead_provider, :teacher, :training_period, :schedule, :school_partnership, :author, :original_schedule

    def initialize(author:, lead_provider:, teacher:, training_period:, schedule:, school_partnership:)
      @lead_provider = lead_provider
      @teacher = teacher
      @training_period = training_period
      @schedule = schedule
      @school_partnership = school_partnership
      @author = author
      @original_schedule = training_period&.schedule
    end

    def change_schedule
      ActiveRecord::Base.transaction do
        track_payments_frozen_year!

        new_training_period = if training_period.started_on.past?
                                create_new_training_period!
                              else
                                update_training_period_in_place!(training_period)
                                training_period
                              end

        if future_training_period_for_same_lead_provider
          update_training_period_in_place!(future_training_period_for_same_lead_provider)
        end

        record_change_schedule_event!(original_training_period: training_period, original_schedule:, new_training_period:)
      end

      teacher
    end

  private

    def update_training_period_in_place!(target_training_period)
      attrs = { schedule: }

      if target_training_period.at_school_period == training_period.at_school_period
        attrs[:school_partnership] = school_partnership
        attrs[:expression_of_interest] = target_training_period.expression_of_interest.present? ? school_partnership.active_lead_provider : nil
      end

      target_training_period.update!(**attrs)
    end

    def create_new_training_period!
      finished_on = determine_finished_on

      finish_training_period!
      create_new_training_period_with!(finished_on:)
    end

    # Determine the correct finished_on date for the new training period.
    # Takes the earliest future date from the following, or nil if none apply:
    #
    # 1. The finished_on of the current training period
    # 2. The finished_on of the school period
    # 3. The started_on of a future training period for the same lead provider (to avoid overlap)
    def determine_finished_on
      [
        training_period.finished_on,
        training_period.at_school_period_finished_on,
        future_training_period_for_same_lead_provider&.started_on
      ].compact.reject(&:past?).min
    end

    def finish_training_period!
      finished_on = [training_period.finished_on, Time.zone.today].compact.min

      if training_period.for_ect?
        TrainingPeriods::Finish.ect_training(
          author:,
          training_period:,
          ect_at_school_period: training_period.at_school_period,
          finished_on:
        ).finish!
      elsif training_period.for_mentor?
        TrainingPeriods::Finish.mentor_training(
          author:,
          training_period:,
          mentor_at_school_period: training_period.at_school_period,
          finished_on:
        ).finish!
      end
    end

    def create_new_training_period_with!(finished_on:)
      TrainingPeriods::Create.provider_led(
        period: training_period.at_school_period,
        started_on: Time.zone.today,
        finished_on:,
        school_partnership:,
        expression_of_interest: nil,
        schedule:,
        author:
      ).call
    end

    def record_change_schedule_event!(original_training_period:, original_schedule:, new_training_period:)
      Events::Record.record_teacher_schedule_changed_event!(
        author:,
        original_training_period:,
        original_schedule:,
        new_training_period:,
        teacher:,
        lead_provider:
      )
    end

    def future_training_period_for_same_lead_provider
      @future_training_period_for_same_lead_provider ||= begin
        scope = if training_period.for_ect?
                  TrainingPeriod.joins(:ect_at_school_period).where(ect_at_school_period: { teacher_id: teacher.id })
                else
                  TrainingPeriod.joins(:mentor_at_school_period).where(mentor_at_school_period: { teacher_id: teacher.id })
                end

        scope
          .where.not(id: training_period.id)
          .started_after(training_period.started_on)
          .joins(school_partnership: { lead_provider_delivery_partnership: { active_lead_provider: :lead_provider } })
          .where(lead_providers: { id: lead_provider.id })
          .earliest_first
          .first
      end
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
