module API::SchoolPartnerships
  class UpdateResource
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :school_partnership_id
    attribute :delivery_partner_api_id

    validates :school_partnership_id, presence: { message: "Enter a '#/school_partnership_id'." }
    validates :delivery_partner_api_id, presence: { message: "Enter a '#/delivery_partner_api_id'." }
    validate :delivery_partner_exists
    validate :school_partnership_exists
    validate :lead_provider_delivery_partnership_exists
    validate :does_not_cause_duplicate_school_partnership

    def update
      return false unless valid?

      SchoolPartnerships::Update.new(
        school_partnership:,
        lead_provider_delivery_partnership:
      ).update
    end

  private

    def school_partnership
      @school_partnership ||= SchoolPartnership.find_by(id: school_partnership_id) if school_partnership_id
    end

    def delivery_partner
      @delivery_partner ||= DeliveryPartner.find_by(api_id: delivery_partner_api_id) if delivery_partner_api_id
    end

    def lead_provider
      @lead_provider ||= school_partnership&.lead_provider
    end

    def active_lead_provider
      @active_lead_provider ||= school_partnership&.active_lead_provider
    end

    def lead_provider_delivery_partnership
      return unless active_lead_provider && delivery_partner

      @lead_provider_delivery_partnership ||= delivery_partner.lead_provider_delivery_partnerships.find_by(active_lead_provider:, delivery_partner:)
    end

    def delivery_partner_exists
      errors.add(:delivery_partner_api_id, "The '#/delivery_partner_api_id' you have entered is invalid. Check delivery partner details and try again.") unless delivery_partner
    end

    def school_partnership_exists
      errors.add(:school_partnership_id, "The '#/school_partnership_id' you have entered is invalid. Check partnership details and try again.") unless school_partnership
    end

    def lead_provider_delivery_partnership_exists
      return unless active_lead_provider && delivery_partner

      errors.add(:delivery_partner_api_id, "The entered delivery partner is not recognised to be working in partnership with you for the given contract period. Contact the DfE for more information.") unless lead_provider_delivery_partnership
    end

    def does_not_cause_duplicate_school_partnership
      return unless school_partnership && lead_provider_delivery_partnership

      existing_school_partnership = school_partnership.school.school_partnerships.exists?(lead_provider_delivery_partnership:)

      errors.add(:delivery_partner_api_id, "We are unable to process this request. You are already confirmed to be in partnership with the entered delivery partner. Contact the DfE for support.") if existing_school_partnership
    end
  end
end
