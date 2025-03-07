class ProgrammeTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, "Select either 'Provider-led' or 'School-led' training")
    elsif !::PROGRAMME_TYPES.keys.include?(value.to_sym)
      record.errors.add(attribute, "'#{value}' is not a valid programme type")
    end
  end
end
