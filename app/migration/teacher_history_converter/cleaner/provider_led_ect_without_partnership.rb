class TeacherHistoryConverter::Cleaner::ProviderLedECTWithoutPartnership
  def initialize(raw_induction_records, participant_type)
    @raw_induction_records = raw_induction_records
    @participant_type = participant_type
  end

  def induction_records
    return @raw_induction_records unless ect?

    remove_provider_led_without_a_partnership!
  end

private

  def ect?
    @participant_type == :ect
  end

  def remove_provider_led_without_a_partnership!
    @raw_induction_records.reject { |induction_record| provider_led_no_partnership?(induction_record) }
  end

  def provider_led_no_partnership?(induction_record)
    provider_led?(induction_record.training_programme) && induction_record.training_provider_info.blank?
  end

  def provider_led?(training_programme)
    Mappers::TrainingProgrammeMapper.new(training_programme).mapped_value == "provider_led"
  end
end
