# Corrects an ECT history where withdrawal details were recorded against a
# later training period instead of the relevant earlier training period.
#
# It moves the withdrawal details to the original period, applies the corrected
# leaving date across linked records, and removes later periods that should no
# longer exist. The supplied periods must have no declarations or events.
module Teachers
  class ECTWithdrawalHistoryCorrection
    attr_reader :ect_at_school_period,
                :original_training_period,
                :erroneous_withdrawn_training_period,
                :corrected_end_date,
                :author

    def initialize(
      ect_at_school_period:,
      original_training_period:,
      erroneous_withdrawn_training_period:,
      corrected_end_date:,
      author:
    )
      @ect_at_school_period = ect_at_school_period
      @original_training_period = original_training_period
      @erroneous_withdrawn_training_period =
        erroneous_withdrawn_training_period
      @corrected_end_date = corrected_end_date
      @author = author
    end

    def correct!
      validate!

      ActiveRecord::Base.transaction do
        move_withdrawal_details!

        ECTAtSchoolPeriods::Finish.new(
          ect_at_school_period:,
          finished_on: corrected_end_date,
          author:,
          record_event: false
        ).finish!
      end
    end

  private

    def move_withdrawal_details!
      original_training_period.update!(
        withdrawn_at: erroneous_withdrawn_training_period.withdrawn_at,
        withdrawal_reason:
          erroneous_withdrawn_training_period.withdrawal_reason
      )
    end

    def validate!
      validate_training_periods!
      validate_period_dates!
      validate_withdrawal_details!
      validate_dependencies!
    end

    def validate_training_periods!
      if original_training_period == erroneous_withdrawn_training_period
        raise "Original and erroneous training periods must be different"
      end

      unless original_training_period.ect_at_school_period ==
          ect_at_school_period
        raise "Original training period does not belong to the ECT-at-school period"
      end

      unless erroneous_withdrawn_training_period.ect_at_school_period ==
          ect_at_school_period
        raise "Erroneous training period does not belong to the ECT-at-school period"
      end
    end

    def validate_period_dates!
      if ect_at_school_period.finished_on.present?
        raise "ECT-at-school period is already finished"
      end

      if corrected_end_date < ect_at_school_period.started_on
        raise "Corrected end date is before the ECT-at-school period start date"
      end

      if original_training_period.started_on > corrected_end_date
        raise "Original training period starts after the corrected end date"
      end

      if original_training_period.finished_on.present? &&
          original_training_period.finished_on < corrected_end_date
        raise "Original training period finishes before the corrected end date"
      end

      if erroneous_withdrawn_training_period.started_on < corrected_end_date
        raise "Erroneous training period starts before the corrected end date"
      end
    end

    def validate_withdrawal_details!
      if original_training_period.withdrawn_at.present? ||
          original_training_period.withdrawal_reason.present?
        raise "Original training period already has withdrawal details"
      end

      if erroneous_withdrawn_training_period.withdrawn_at.blank? ||
          erroneous_withdrawn_training_period.withdrawal_reason.blank?
        raise "Erroneous training period has incomplete withdrawal details"
      end
    end

    def validate_dependencies!
      if original_training_period.declarations.exists?
        raise "Original training period has declarations"
      end

      if original_training_period.events.exists?
        raise "Original training period has events"
      end

      if erroneous_withdrawn_training_period.declarations.exists?
        raise "Erroneous training period has declarations"
      end

      if erroneous_withdrawn_training_period.events.exists?
        raise "Erroneous training period has events"
      end
    end
  end
end
