# Corrects an ECT history where withdrawal details were recorded against a
# later training period instead of the relevant earlier training period.
#
# It moves the withdrawal details to the target period, applies the corrected
# leaving date across linked records, and removes later periods that should no
# longer exist. The supplied periods must have no declarations or events.
module Teachers
  class ECTWithdrawalHistoryCorrection
    attr_reader :ect_at_school_period,
                :source_training_period,
                :target_training_period,
                :corrected_finished_on,
                :author

    def initialize(
      ect_at_school_period:,
      source_training_period:,
      target_training_period:,
      corrected_finished_on:,
      author:
    )
      @ect_at_school_period = ect_at_school_period
      @source_training_period = source_training_period
      @target_training_period = target_training_period
      @corrected_finished_on = corrected_finished_on
      @author = author
    end

    def correct!
      validate!

      ActiveRecord::Base.transaction do
        move_withdrawal_details!

        ECTAtSchoolPeriods::Finish.new(
          ect_at_school_period:,
          finished_on: corrected_finished_on,
          author:,
          record_event: false
        ).finish!
      end
    end

  private

    def move_withdrawal_details!
      target_training_period.update!(
        withdrawn_at: source_training_period.withdrawn_at,
        withdrawal_reason: source_training_period.withdrawal_reason
      )
    end

    def validate!
      validate_training_periods!
      validate_period_dates!
      validate_withdrawal_details!
      validate_dependencies!
    end

    def validate_training_periods!
      if source_training_period == target_training_period
        raise "Source and target training periods must be different"
      end

      unless source_training_period.ect_at_school_period ==
          ect_at_school_period
        raise "Source training period does not belong to the ECT-at-school period"
      end

      unless target_training_period.ect_at_school_period ==
          ect_at_school_period
        raise "Target training period does not belong to the ECT-at-school period"
      end
    end

    def validate_period_dates!
      if ect_at_school_period.finished_on.present?
        raise "ECT-at-school period is already finished"
      end

      if corrected_finished_on < ect_at_school_period.started_on
        raise "Corrected finish date is before the ECT-at-school period start date"
      end

      if target_training_period.started_on > corrected_finished_on
        raise "Target training period starts after the corrected finish date"
      end

      if target_training_period.finished_on.present? &&
          target_training_period.finished_on < corrected_finished_on
        raise "Target training period finishes before the corrected finish date"
      end

      if source_training_period.started_on < corrected_finished_on
        raise "Source training period starts before the corrected finish date"
      end
    end

    def validate_withdrawal_details!
      if target_training_period.withdrawn_at.present? ||
          target_training_period.withdrawal_reason.present?
        raise "Target training period already has withdrawal details"
      end

      if source_training_period.withdrawn_at.blank? ||
          source_training_period.withdrawal_reason.blank?
        raise "Source training period has incomplete withdrawal details"
      end
    end

    def validate_dependencies!
      if target_training_period.declarations.exists?
        raise "Target training period has declarations"
      end

      if target_training_period.events.exists?
        raise "Target training period has events"
      end

      if source_training_period.declarations.exists?
        raise "Source training period has declarations"
      end

      if source_training_period.events.exists?
        raise "Source training period has events"
      end
    end
  end
end