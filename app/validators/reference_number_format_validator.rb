class ReferenceNumberFormatValidator < ActiveModel::EachValidator
  DIGITS_ONLY_PATTERN = /\A\d+\z/

  def validate_each(record, attribute, value)
    return if options[:allow_blank] && value.blank?

    reference_number = value.to_s
    too_long = options[:maximum] && reference_number.length > options[:maximum]
    too_short = options[:minimum] && reference_number.length < options[:minimum]
    not_numeric = !reference_number.match?(DIGITS_ONLY_PATTERN)
    wrong_pattern = options[:with] && !reference_number.match?(options[:with])

    if too_long || too_short || not_numeric || wrong_pattern
      record.errors.add(attribute, options[:message] || "is invalid")
    end
  end
end
