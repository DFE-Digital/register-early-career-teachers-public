class SchoolPeriodExtractor
  include Enumerable

  def initialize(participant_profile:)
    @induction_records = InductionRecordSanitizer.new(participant_profile:)
    @induction_records.validate!
  end

  def each
    return to_enum(__method__) { school_periods.size } unless block_given?

    school_periods.each { |school_period| yield school_period }
  end
  
private

  def school_periods
    @school_periods ||= build_school_periods
  end

  def build_school_periods
    periods = []
    current_period = {}
    current_school = nil

    @induction_records.each do |induction_record|
      record_school = induction_record.induction_programme.school_cohort.school

      if current_school != record_school
        current_school = record_school

        current_period = { school: current_school, start_date: induction_record.start_date, end_date: induction_record.end_date }
        periods << current_period
      else
        current_period[:end_date] = induction_record.end_date
      end
    end

    periods
  end
end
