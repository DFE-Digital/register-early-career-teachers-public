module Teachers::SchoolTransfers
  class History
    def self.transfers_for(...) = new(...).transfers
    def self.exists_for?(...) = new(...).exists?

    def initialize(school_periods:, lead_provider_id:)
      @school_periods = school_periods.sort_by(&:started_on)
      @lead_provider_id = lead_provider_id
    end

    def transfers
      @school_periods.map.with_index { |school_period, index|
        next_school_period = @school_periods[index + 1]
        transfer_for(school_period, next_school_period)
      }.compact
    end

    def exists?
      @school_periods.map.with_index.any? do |school_period, index|
        next_school_period = @school_periods[index + 1]
        transfer_for(school_period, next_school_period)
      end
    end

  private

    def transfer_for(school_period, next_school_period)
      return unless school_period.complete?

      leaving_training_period = school_period.latest_training_period
      return unless leaving_training_period&.complete?

      return unless different_school?(school_period, next_school_period)
      return if teacher_completed_induction?(school_period.teacher, next_school_period)

      joining_training_period = next_school_period&.earliest_training_period
      return unless relevant_to_lead_provider?(leaving_training_period, joining_training_period)

      Transfer.new(
        leaving_training_period:,
        leaving_school: school_period.school,
        joining_training_period:,
        joining_school: next_school_period&.school
      )
    end

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
