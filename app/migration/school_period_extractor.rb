class SchoolPeriodExtractor
  include Enumerable

  attr_reader :induction_records

  def initialize(induction_records:)
    @induction_records = induction_records
  end

  def each(&block)
    return to_enum(__method__) { school_periods.size } unless block_given?

    school_periods.each(&block)
  end

private

  def school_periods
    @school_periods ||= build_school_periods
  end

  def build_school_periods
    periods = build_school_periods_from_induction_records
    periods = add_school_mentor_periods_to_school_periods(periods) if mentor?

    periods
  end

  def build_school_periods_from_induction_records
    current_period = nil
    current_school = nil

    induction_records.each_with_object([]) do |induction_record, periods|
      record_school = induction_record.induction_programme.school_cohort.school
      training_programme = discover_training_programme(induction_record)
      lead_provider_id = discover_lead_provider_id(induction_record, training_programme)

      if current_school != record_school
        current_school = record_school

        current_period = Migration::SchoolPeriod.new(urn: current_school.urn,
                                                     start_date: induction_record.start_date,
                                                     end_date: induction_record.end_date,
                                                     start_source_id: induction_record.id,
                                                     end_source_id: induction_record.id,
                                                     training_programme:,
                                                     lead_provider_id:)
        periods << current_period
      else
        current_period.end_date = induction_record.end_date
        current_period.end_source_id = induction_record.id
      end
    end
  end

  def add_school_mentor_periods_to_school_periods(periods)
    SchoolMentorsToSchoolPeriods.new(participant_profile:).each do |mentor_period|
      next if periods.find { |sp| sp.urn == mentor_period.urn }

      periods << mentor_period
    end

    periods.sort_by(&:start_date)
  end

  def mentor?
    participant_profile.mentor?
  end

  def participant_profile
    @participant_profile ||= induction_records.first.participant_profile
  end

  def discover_training_programme(induction_record)
    extracted_training_programme = induction_record.induction_programme.training_programme
    Mappers::TrainingProgrammeMapper.new(extracted_training_programme).mapped_value
  end

  def discover_lead_provider_id(induction_record, training_programme)
    return nil if training_programme == 'school_led'

    return nil if induction_record.induction_programme.partnership.nil?

    extracted_lead_provider_name = induction_record.induction_programme.partnership.lead_provider.name
    LeadProvider.find_by(name: extracted_lead_provider_name).id
  end
end
