class FutureDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.errors[attribute].any?

    if value && value > Time.zone.now
      record.errors.add(attribute, sprintf("The '#/%{attribute}' value cannot be a future date. Check the date and try again.", attribute:))
    end
  end
end
