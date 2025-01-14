class WorkingPatternValidator < ActiveModel::EachValidator
  VALID_WORKING_PATTERNS = %w[part_time full_time].freeze

  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, "Select if the ECT's working pattern is full or part time")
    elsif !VALID_WORKING_PATTERNS.include?(value)
      record.errors.add(attribute, "'#{value}' is not a valid working pattern")
    end
  end
end
