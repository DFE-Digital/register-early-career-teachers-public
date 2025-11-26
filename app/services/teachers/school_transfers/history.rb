module Teachers::SchoolTransfers
  class History
    def self.transfers_for(...) = new(...).transfers

    def initialize(school_periods:, lead_provider_id:)
      @school_periods = school_periods.earliest_first
      @lead_provider_id = lead_provider_id
    end

    def transfers
      @school_periods.map.with_index { |school_period, index|
        next unless school_period.complete?

        leaving_training_period = school_period.latest_training_period
        next unless leaving_training_period&.complete?

        next_school_period = @school_periods[index + 1]
        next unless different_school?(school_period, next_school_period)
        next if teacher_completed_induction?(school_period.teacher, next_school_period)

        joining_training_period = next_school_period&.earliest_training_period
        next unless relevant_to_lead_provider?(leaving_training_period, joining_training_period)

        Transfer.new(
          leaving_training_period:,
          leaving_school: school_period.school,
          joining_training_period:,
          joining_school: next_school_period&.school
        )
      }.compact
    end

  private

    def different_school?(school_period, next_school_period)
      school_period.school != next_school_period&.school
    end

    def teacher_completed_induction?(teacher, next_school_period)
      finished_induction_period = teacher.finished_induction_period
      next_school_period.nil? && finished_induction_period&.complete?
    end

    def relevant_to_lead_provider?(leaving_training_period, joining_training_period)
      leaving_training_period.lead_provider&.id == @lead_provider_id ||
        joining_training_period&.lead_provider&.id == @lead_provider_id
    end
  end
end
