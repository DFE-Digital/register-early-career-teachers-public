class ImmutableOnceSetValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    old_value = record.public_send("#{attribute}_was")
    return if old_value.nil? || old_value == value

    record.errors.add(attribute, "cannot be changed once set")
  end
end
