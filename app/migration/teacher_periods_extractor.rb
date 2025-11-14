class TeacherPeriodsExtractor
  include Enumerable
  include DataFixes

  attr_reader :induction_records

  def initialize(induction_records:)
    @induction_records = induction_records
  end

  def each(&block)
    return to_enum(__method__) { teacher_periods.size } unless block_given?

    teacher_periods.each(&block)
  end

  def teacher_periods
    @teacher_periods ||= build_periods
  end

private

  def build_periods
    # get school periods
    # for each school period get training period
    current_period = nil
    current_school = nil
    current_training = nil

    induction_records.each_with_object([]).with_index do |(induction_record, periods), idx|
      record_school = induction_record.induction_programme.school_cohort.school

      if current_school != record_school
        # start at a new school
        current_school = record_school

        start_date = corrected_start_date(induction_record:, sequence_number: idx)

        # TODO: adjust first period date
        current_period = Migration::SchoolPeriod.new(urn: current_school.urn,
                                                     start_date:,
                                                     end_date: induction_record.end_date,
                                                     start_source_id: induction_record.id,
                                                     end_source_id: induction_record.id)

        # new school means new training period
        current_training = extract_training_data_from(induction_record:)
        current_period.training_periods << current_training
        periods << current_period
      elsif training_changed?(current_training, induction_record)
        # school hasn't changed but training has
        # TODO: close current training?
        current_training = extract_training_data_from(induction_record:)
        current_period.training_periods << current_training
      else
        # nothing has changed regarding periods other than end_date
        current_period.end_date = induction_record.end_date
        current_period.end_source_id = induction_record.id
        current_training.end_date = induction_record.end_date
        current_training.end_source_id = induction_record.id
      end
    end
  end

  def training_changed?(current_training, induction_record)
    return true if current_training.nil?

    induction_programme = induction_record.induction_programme
    training_programme = mapped_training_programme(induction_programme.training_programme)

    training_programme != current_training.training_programme ||
      induction_programme.partnership&.lead_provider&.name != current_training.lead_provider ||
      induction_programme.partnership&.delivery_partner&.name != current_training.delivery_partner
  end

  def extract_training_data_from(induction_record:)
    induction_programme = induction_record.induction_programme
    training_programme = mapped_training_programme(induction_programme.training_programme)
    lead_provider = induction_programme.partnership&.lead_provider&.name
    delivery_partner = induction_programme.partnership&.delivery_partner&.name
    core_materials = induction_programme.core_induction_programme&.name
    school_urn = induction_programme.school_cohort.school.urn

    end_date = if induction_records.count == 1
                 corrected_training_period_end_date(induction_record:)
               else
                 induction_record.end_date
               end

    Migration::TrainingPeriodData.new(training_programme:,
                                      school_urn:,
                                      lead_provider:,
                                      delivery_partner:,
                                      core_materials:,
                                      cohort_year: induction_record.schedule.cohort.start_year,
                                      start_date: induction_record.start_date,
                                      end_date:,
                                      start_source_id: induction_record.id,
                                      end_source_id: induction_record.id)
  end

  def mapped_training_programme(ecf_training)
    Mappers::TrainingProgrammeMapper.new(ecf_training).mapped_value
  end
end
