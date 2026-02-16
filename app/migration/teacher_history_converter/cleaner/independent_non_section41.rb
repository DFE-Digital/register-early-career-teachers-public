class TeacherHistoryConverter::Cleaner::IndependentNonSection41
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records = remove_unneeded_independent_school_records!

private

  def remove_unneeded_independent_school_records!
    records_to_keep = []

    school_groups = @raw_induction_records.group_by { |induction_record| induction_record.school.urn }

    school_groups.each_value do |induction_records|
      next unless not_an_independent_school?(induction_records.first.school) ||
        any_fip_training?(induction_records) ||
        all_school_led_with_section_41?(induction_records)

      records_to_keep << induction_records
    end

    records_to_keep.flatten
  end

  def not_an_independent_school?(school)
    !GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(school.school_type_name)
  end

  def any_fip_training?(induction_records)
    induction_records.any? { |induction_record| induction_record.training_programme == "full_induction_programme" }
  end

  def all_school_led_with_section_41?(induction_records)
    return false unless induction_records.all? { |induction_record| school_led?(induction_record.training_programme) }

    first_ir = induction_records.min_by(&:start_date)

    # check the IR started during a time when the school had section 41 approval
    created_when_s41_approval_granted?(first_ir)
  end

  def school_led?(training_programme)
    Mappers::TrainingProgrammeMapper.new(training_programme).mapped_value == "school_led"
  end

  def created_when_s41_approval_granted?(induction_record)
    urn = induction_record.school.urn

    s41 = s41_data.find { |row| row["urn"] == urn }

    return false if s41.blank?

    revoked_on = s41["s41_revoked"]
    granted_on = s41["s41_granted"]

    (revoked_on.present? && Date.parse(revoked_on) > induction_record.start_date) ||
      (granted_on.present? && Date.parse(granted_on) < induction_record.start_date)
  end

  def s41_data
    @s41_data ||= Section41Reader.new.section41_approvals
  end
end
