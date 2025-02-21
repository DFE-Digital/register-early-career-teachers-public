class LeadProviderValidator < ActiveModel::Validator
  def validate(record)
    if record.lead_provider_id.blank?
      record.errors.add(:lead_provider_id, "Select which lead provider will be training the ECT")
    end
    unless LeadProvider.exists?(record.lead_provider_id)
      record.errors.add(:lead_provider_id, "Enter the name of a known lead provider")
    end
  end
end
