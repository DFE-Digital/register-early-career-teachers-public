class MentorshipPeriodExtractor
  include Enumerable
  include DataFixes

  def initialize(induction_records:)
    @induction_records = induction_records
    @last_created_induction_record = induction_records.max_by(&:created_at)
  end

  def each(&block)
    return to_enum(__method__) { mentorship_periods.size } unless block_given?

    mentorship_periods.each(&block)
  end

  def mentorship_periods
    @mentorship_periods ||= build_mentorship_periods
  end

private

  attr_reader :last_created_induction_record

  def build_mentorship_periods
    current_period = nil
    current_mentor_id = nil

    @induction_records.each_with_object([]) do |induction_record, periods|
      mentor_id = induction_record.mentor_profile_id

      next if current_mentor_id.nil? && mentor_id.nil?

      end_date = corrected_end_date(induction_record:, last_created: last_created_induction_record?(induction_record))

      if current_mentor_id.present? && mentor_id.nil?
        current_mentor_id = nil
      elsif current_mentor_id != mentor_id
        current_mentor_id = mentor_id

        mentor_teacher = ::Teacher.find_by(api_mentor_training_record_id: mentor_id)

        current_period = Migration::MentorshipPeriodData.new(mentor_teacher:,
                                                             start_date: induction_record.start_date,
                                                             end_date:,
                                                             start_source_id: induction_record.id,
                                                             end_source_id: induction_record.id)
        periods << current_period
      else
        current_period.end_date = end_date
        current_period.end_source_id = induction_record.id
      end
    end
  end

  def last_created_induction_record?(induction_record) = induction_record.id == last_created_induction_record.id
end
