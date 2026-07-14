module Teachers
  class CorrectWithdrawalAndPeriods
    ECT_STARTED_ON = Date.new(2023, 9, 11)
    ORIGINAL_FINISHED_ON = Date.new(2023, 11, 23)
    CORRECT_FINISHED_ON = Date.new(2023, 11, 10)

    ERRONEOUS_TRAINING_STARTED_ON = Date.new(2025, 10, 7)
    ERRONEOUS_TRAINING_FINISHED_ON = Date.new(2025, 11, 6)

    EXPECTED_WITHDRAWN_AT = Time.zone.parse("2025-11-06T12:20:55Z")
    EXPECTED_WITHDRAWAL_REASON = "other"

    attr_reader :ect_at_school_period, :author

    def initialize(ect_at_school_period:, author:)
      @ect_at_school_period = ect_at_school_period
      @author = author
    end

    def correct!
      validate_current_state!

      ActiveRecord::Base.transaction do
        copy_withdrawal_details!

        # Finishing the ECT-at-school period also brings the current linked training
        # and mentorship periods back to this date and removes later erroneous periods
        ECTAtSchoolPeriods::Finish.new(
          ect_at_school_period:,
          finished_on: CORRECT_FINISHED_ON,
          author:,
          record_event: false
        ).finish!
      end
    end

  private

    def original_training_period
      @original_training_period ||= ect_at_school_period.training_periods.find_by!(
        started_on: ECT_STARTED_ON
      )
    end

    def erroneous_training_period
      @erroneous_training_period ||= ect_at_school_period.training_periods.find_by!(
        started_on: ERRONEOUS_TRAINING_STARTED_ON
      )
    end

    def mentorship_period
      @mentorship_period ||= ect_at_school_period.mentorship_periods.find_by!(
        started_on: ECT_STARTED_ON
      )
    end

    def copy_withdrawal_details!
      original_training_period.update!(
        withdrawn_at: erroneous_training_period.withdrawn_at,
        withdrawal_reason: erroneous_training_period.withdrawal_reason
      )
    end

    def validate_current_state!
      validate_ect_at_school_period!
      validate_original_training_period!
      validate_erroneous_training_period!
      validate_mentorship_period!
    end

    def validate_ect_at_school_period!
      unless ect_at_school_period.started_on == ECT_STARTED_ON
        raise "Unexpected ECT-at-school start date"
      end

      if ect_at_school_period.finished_on.present?
        raise "ECT-at-school period is already finished"
      end
    end

    def validate_original_training_period!
      unless original_training_period.finished_on == ORIGINAL_FINISHED_ON
        raise "Unexpected original training-period end date"
      end

      if original_training_period.withdrawn_at.present? ||
          original_training_period.withdrawal_reason.present?
        raise "Original training period already has withdrawal details"
      end

      if original_training_period.declarations.exists?
        raise "Original training period has declarations"
      end

      if original_training_period.events.exists?
        raise "Original training period has events"
      end
    end

    def validate_erroneous_training_period!
      unless erroneous_training_period.finished_on ==
          ERRONEOUS_TRAINING_FINISHED_ON
        raise "Unexpected erroneous training-period end date"
      end

      unless erroneous_training_period.withdrawn_at&.to_i ==
          EXPECTED_WITHDRAWN_AT.to_i
        raise "Unexpected withdrawal timestamp"
      end

      unless erroneous_training_period.withdrawal_reason ==
          EXPECTED_WITHDRAWAL_REASON
        raise "Unexpected withdrawal reason"
      end

      if erroneous_training_period.declarations.exists?
        raise "Erroneous training period has declarations"
      end

      if erroneous_training_period.events.exists?
        raise "Erroneous training period has events"
      end
    end

    def validate_mentorship_period!
      if mentorship_period.finished_on.present?
        raise "Mentorship period is already finished"
      end
    end
  end
end
