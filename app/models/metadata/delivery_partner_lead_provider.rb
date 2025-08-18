module Metadata
  class DeliveryPartnerLeadProvider < Metadata::Base
    self.table_name = :metadata_delivery_partners_lead_providers

    belongs_to :delivery_partner
    belongs_to :lead_provider

    validates :delivery_partner, presence: true
    validates :lead_provider, presence: true
    validates :delivery_partner_id, uniqueness: { scope: :lead_provider_id }
    validate :contract_period_years_is_an_array_of_valid_years

  private

    def contract_period_years_is_an_array_of_valid_years
      if contract_period_years.nil? || !contract_period_years.is_a?(Array)
        errors.add(:contract_period_years, "must be an array")
      elsif contract_period_years.present? && contract_period_years.any? { |year| !year.between?(2021, Date.current.year) }
        errors.add(:contract_period_years, "must contain valid years between 2021 and the current year")
      end
    end
  end
end
