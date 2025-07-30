class InductionRecordSanitizer
  include Enumerable

  class InductionRecordError < StandardError; end
  class MultipleBlankEndDateError < InductionRecordError; end
  class MultipleActiveStatesError < InductionRecordError; end
  class StartDateAfterEndDateError < InductionRecordError; end
  class InvalidDateSequenceError < InductionRecordError; end
  class NoInductionRecordsError < InductionRecordError; end

  attr_reader :participant_profile, :error, :group_by

  def initialize(participant_profile:, group_by: :none)
    @participant_profile = participant_profile
    @group_by = group_by.to_sym
    @error = nil
  end

  def valid?
    @error = nil
    validate!
    true
  rescue InductionRecordError => e
    @error = e.message
    false
  end

  def validate!
    has_induction_records!

    case group_by
    when :school, :provider
      induction_records.each do |_subject, induction_record_group|
        does_not_have_multiple_blank_end_dates!(induction_record_group)
        does_not_have_multiple_active_induction_statuses!(induction_record_group)
        # induction_record_dates_are_sequential!(induction_record_group)
      end
    when :none
      does_not_have_multiple_blank_end_dates!(induction_records)
      does_not_have_multiple_active_induction_statuses!(induction_records)
      # induction_record_dates_are_sequential!(induction_records)
    else
      raise InductionRecordError, "invalid grouping specified [#{group_by}]"
    end
  end

  def validate_and_compress!
    validate!

    last_induction_record = nil
    induction_records.each_with_object([]) do |induction_record, result|
      if different?(induction_record, last_induction_record)
        result << induction_record
        last_induction_record = induction_record
      end
    end
  end

  def each(&block)
    return to_enum(__method__) { induction_records.size } unless block_given?

    case group_by
    when :school
      enumerate_by_school(&block)
    when :provider
      enumerate_by_provider(&block)
    when :none
      induction_records.each do |induction_record|
        yield Migration::InductionRecordPresenter.new(induction_record)
      end
    else
      raise InductionRecordError, "invalid grouping specified [#{group_by}]"
    end
  end

  def induction_records
    @induction_records ||= ordered_induction_records
  end

private

  def ordered_induction_records
    case group_by
    when :school
      participant_profile
        .induction_records
        .eager_load(induction_programme: [school_cohort: :school])
        .order(:start_date, :created_at)
        .group_by { |ir| ir.induction_programme.school_cohort.school.urn }
    when :provider
      participant_profile
        .induction_records
        .eager_load(induction_programme: :partnership)
        .order(:start_date, :created_at)
        .group_by { |ir| ir.induction_programme.partnership&.lead_provider_id }
    when :none
      participant_profile
        .induction_records
        .eager_load(induction_programme: [school_cohort: :school])
        .order(:start_date, :created_at)
    else
      raise InductionRecordError, "invalid grouping specified [#{group_by}]"
    end
  end

  def enumerate_by_provider
    induction_records.each do |lead_provider_id, induction_record_group|
      induction_record_group.each do |induction_record|
        yield lead_provider_id, Migration::InductionRecordPresenter.new(induction_record)
      end
    end
  end

  def enumerate_by_school
    induction_records.each do |urn, induction_record_group|
      induction_record_group.each do |induction_record|
        yield urn, Migration::InductionRecordPresenter.new(induction_record)
      end
    end
  end

  def different?(ir1, ir2)
    ignored_attrs = %w[id start_date end_date created_at updated_at].freeze

    return true if ir1.nil? || ir2.nil?

    ir1.attributes.except(*ignored_attrs) != ir2.attributes.except(*ignored_attrs)
  end

  def has_induction_records!
    raise(NoInductionRecordsError) if participant_profile.induction_records.empty?
  end

  def does_not_have_multiple_blank_end_dates!(induction_record_collection)
    raise(MultipleBlankEndDateError) if induction_record_collection.select { |ir| ir.end_date.nil? }.count > 1
  end

  def does_not_have_multiple_active_induction_statuses!(induction_record_collection)
    raise(MultipleActiveStatesError) if induction_record_collection.select { |ir| ir.induction_status == "active" }.count > 1
  end

  # NOTE: Ignore the end_date for validation as we will concentrate on the start_date
  # def induction_record_dates_are_sequential!(induction_record_collection)
  #   previous_end_date = induction_record_collection.first.end_date

  #   induction_record_collection.each_with_index do |ir, idx|
  #     raise(StartDateAfterEndDateError) if ir.end_date.present? && ir.end_date < ir.start_date

  #     next if idx.zero?

  #     raise(InvalidDateSequenceError) if previous_end_date.nil? || ir.start_date < previous_end_date

  #     previous_end_date = ir.end_date
  #   end
  # end
end
