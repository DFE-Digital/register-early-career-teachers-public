class DeclarationDateFormatValidator < ActiveModel::Validator
  RFC3339_DATE_REGEX = /\A\d{4}-\d{2}-\d{2}T(\d{2}):(\d{2}):(\d{2})([.,]\d+)?(Z|[+-](\d{2})(:?\d{2})?)?\z/i

  def validate(record)
    date_has_the_right_format(record)
  end

private

  def date_has_the_right_format(record)
    return if record.errors[:declaration_date].any?
    return if record.declaration_date.blank?

    return if record.declaration_date.match?(RFC3339_DATE_REGEX) && begin
      Time.zone.parse(record.declaration_date.to_s)
    rescue ArgumentError
      false
    end

    record.errors.add(:declaration_date, "Enter a valid RCF3339 '#/declaration_date'.")
  end
end
