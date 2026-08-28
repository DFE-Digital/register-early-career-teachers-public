module API::FindLeadProvider
  extend ActiveSupport::Concern

  included do
    validates :lead_provider_id, presence: { message: "Enter a '#/lead_provider_id'." }
    validate :lead_provider_exists
  end

private

  def lead_provider
    @lead_provider ||= LeadProvider.find_by(id: lead_provider_id) if lead_provider_id
  end

  def lead_provider_exists
    return if errors.any?
    return if lead_provider

    errors.add(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.")
  end
end
