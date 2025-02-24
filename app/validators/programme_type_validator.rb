class ProgrammeTypeValidator < ActiveModel::EachValidator
  VALID_PROGRAMME_TYPES = {
    'provider_led' => 'Provider-led',
    'school_led' => 'School-led'
  }.freeze

  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, "Select either 'Provider-led' or 'School-led' training")
    elsif !VALID_PROGRAMME_TYPES.keys.include?(value)
      record.errors.add(attribute, "'#{value}' is not a valid programme type")
    end
  end
end
