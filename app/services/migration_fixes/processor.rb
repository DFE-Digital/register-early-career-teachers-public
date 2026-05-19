class MigrationFixes::Processor
  attr_reader :batch_refs

  def initialize
    @batch_refs = {}
  end

  def process!(data_change: {})
    return if data_change.blank? || data_change.empty?

    object_type = data_change[:object_type].camelcase.constantize
    object_id = data_change[:object_id]
    action = data_change[:action]

    target_object = object_type.find(object_id) unless action == "create"

    case action
    when "create"
      target_object = create!(object_type, extract_attributes(data_change[:attributes]))
      if object_id.present?
        # treat as a batch reference ID to be used be a subsequent change
        batch_refs[object_id] = target_object.id
      end
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
    ActiveRecord::Base.transaction do
      remove_references_to!(target_object)
      target_object.destroy
    end
  end

  def remove_references_to!(target_object)
    if target_object.is_a? School
      Metadata::SchoolLeadProviderContractPeriod.where(school: target_object).delete_all
      Metadata::SchoolContractPeriod.where(school: target_object).delete_all
    end
  end

  def extract_attributes(attributes_list)
    # attributes_list is a string of comma delimited key-value pairs
    # we want to turn that into a hash
    return {} if attributes_list.blank?

    attrs = {}

    attributes_list.split(",").each_slice(2) do |k, v|
      if batch_refs.key?(v)
        v = batch_refs[v]
      end
      attrs[k.to_sym] = v
    end

    attrs
  end
end
