class APIDateTimeFormatValidator < ActiveModel::EachValidator
  RFC3339_DATE_REGEX = /\A\d{4}-\d{2}-\d{2}T(\d{2}):(\d{2}):(\d{2})([.,]\d+)?(Z|[+-](\d{2})(:?\d{2})?)?\z/i

  def validate_each(record, attribute, value)
    return if record.errors[attribute].any?

    date_has_the_right_format(record, attribute, value)
  end

private

  def date_has_the_right_format(record, attribute, value)
    return if value.blank?

    return if value.match?(RFC3339_DATE_REGEX) && begin
      Time.zone.parse(value.to_s)
    rescue ArgumentError
      false
    end

    record.errors.add(attribute, "Enter a valid RCF3339 '#/#{attribute}'.")
  end
end
