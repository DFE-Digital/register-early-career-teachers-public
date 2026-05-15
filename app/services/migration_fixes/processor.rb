class MigrationFixes::Processor
  def process!(data_change: {})
    return if data_change.blank? || data_change.empty?

    object_type = data_change[:object_type].camelcase.constantize
    object_id = data_change[:object_id]
    action = data_change[:action]

    target_object = object_type.find(object_id) unless action == "create"

    case action
    when "create"
      target_object = create!(object_type, extract_attributes(data_change[:attributes]))
    when "update"
      update!(target_object, extract_attributes(data_change[:attributes]))
    when "delete"
      delete!(target_object)
    else
      raise ArgumentError, "Unknown action '#{action}'"
    end

    target_object
  end

private

  def create!(object_type, attrs)
    object_type.create!(**attrs)
  end

  def update!(target_object, attrs)
    return if attrs.blank?

    target_object.update!(**attrs)
  end

  def delete!(target_object)
    target_object.destroy
  end

  def extract_attributes(attributes_list)
    # attributes_list is a string of comma delimited key-value pairs
    # we want to turn that into a hash
    return {} if attributes_list.blank?

    attrs = {}

    attributes_list.split(",").each_slice(2) { |k, v| attrs[k.to_sym] = v }

    attrs
  end
end
