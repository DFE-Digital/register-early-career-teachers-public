# frozen_string_literal: true

module API::SchoolPartnerships
  class Update
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :school_partnership
    attribute :delivery_partner_ecf_id

    validates :school_partnership, :delivery_partner_ecf_id, presence: true
    validate :delivery_partner_exists
    validate :lead_provider_delivery_partnership_exists
    validate :school_partnership_does_not_already_exists

    def update
      return false unless valid?

      school_partnership.update!(lead_provider_delivery_partnership:)
    end

  private

    def delivery_partner
      @delivery_partner ||= DeliveryPartner.find_by(ecf_id: delivery_partner_ecf_id) if delivery_partner_ecf_id
    end

    def lead_provider
      @lead_provider ||= school_partnership.lead_provider
    end

    def lead_provider_active_period
      @lead_provider_active_period ||= school_partnership.lead_provider_active_period
    end

    def lead_provider_delivery_partnership
      return unless school_partnership && delivery_partner

      @lead_provider_delivery_partnership ||= delivery_partner.lead_provider_delivery_partnerships.find_by(lead_provider_active_period:, delivery_partner:)
    end

    def delivery_partner_exists
      errors.add(:delivery_partner_ecf_id, "Delivery partner does not exist") unless delivery_partner
    end

    def lead_provider_delivery_partnership_exists
      return unless school_partnership && delivery_partner

      errors.add(:delivery_partner_ecf_id, "Lead provider and delivery partner do not have a partnership") unless lead_provider_delivery_partnership
    end

    def school_partnership_does_not_already_exists
      return unless school_partnership && lead_provider_delivery_partnership

      existing_school_partnership = school_partnership.school.school_partnerships.exists?(lead_provider_delivery_partnership:)

      errors.add(:school_ecf_id, "School partnership already exists for the lead provider, delivery partner and registration year") if existing_school_partnership
    end
  end
end
