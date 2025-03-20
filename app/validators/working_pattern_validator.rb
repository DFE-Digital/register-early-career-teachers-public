class WorkingPatternValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, "Select if the ECT's working pattern is full or part time")
    elsif !::WORKING_PATTERNS.key?(value.to_sym)
      record.errors.add(attribute, "'#{value}' is not a valid working pattern")
    end
  end
end
