class APIDateTimeFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.errors[attribute].any?

    date_has_the_right_format(record, attribute, value)
  end

private

  def date_has_the_right_format(record, attribute, value)
    return if value.blank?

    return if API::DateTimeFormatCheck.new(value).valid?

    record.errors.add(attribute, "Enter a valid RFC3339 '#/#{attribute}'.")
  end
end
