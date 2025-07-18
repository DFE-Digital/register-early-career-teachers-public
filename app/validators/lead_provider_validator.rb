class LeadProviderValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return if record.errors[attribute].any?
    return if LeadProvider.find_by(id: value)

    message = options[:message] || "Select a lead provider"
    record.errors.add(attribute, message)
  end
end
