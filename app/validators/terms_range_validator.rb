class TermsRangeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    range = record.class::VALID_NUMBER_OF_TERMS
    min, max = range.values_at(:min, :max)

    unless (min..max).cover?(value)
      record.errors.add(attribute, "Number of terms must be between #{min} and #{max}")
    end
  end
end
