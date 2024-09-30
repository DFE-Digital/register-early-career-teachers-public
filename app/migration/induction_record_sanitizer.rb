class InductionRecordSanitizer
  include Enumerable

  class MultipleBlankEndDateError < StandardError; end
  class MultipleActiveStatesError < StandardError; end
  class StartDateAfterEndDateError < StandardError; end
  class InvalidDateSequence < StandardError; end

  attr_reader :participant_profile

  def initialize(participant_profile:)
    @participant_profile = participant_profile
  end

  def validate!
    # TODO: I imagine there will be a lot of things needed in here to check/report on
    does_not_have_multiple_blank_end_dates!
    does_not_have_multiple_active_induction_statuses!
    induction_record_dates_are_sequential!
  end

  def compress!
    induction_records.uniq do |ir|
      [ir.induction_programme_id,
       ir.appropriate_body_id,
       ir.mentor_profile_id,
       ir.schedule_id,
       ir.preferred_identity_id,
       ir.induction_status,
       ir.training_status
      ]
    end
  end

  def each
    return to_enum(__method__) { induction_records.size } unless block_given?

    induction_records.each { |induction_record| yield induction_record }
  end

private

  def induction_records
    @induction_records ||= participant_profile.induction_records.includes(induction_programme: [{ school_cohort: [:school] }]).order(start_date: :asc)
  end

  def does_not_have_multiple_blank_end_dates!
    raise MultipleBlankEndDateError if induction_records.where(end_date: nil).count > 1
  end

  def does_not_have_multiple_active_induction_statuses!
    raise MultipleActiveStatesError if induction_records.where(induction_status: :active).count > 1
  end

  def induction_record_dates_are_sequential!
    previous_end_date = induction_records.first.end_date

    induction_records.each_with_index do |ir, idx|
      raise StartDateAfterEndDateError if ir.end_date.present? && ir.end_date < ir.start_date

      next if idx.zero?

      raise InvalidDateSequenceError if ir.start_date < previous_end_date
      
      previous_end_date = ir.end_date
    end
  end
end
