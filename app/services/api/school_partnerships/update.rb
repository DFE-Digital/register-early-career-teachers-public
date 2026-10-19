module API::SchoolPartnerships
  class Update
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :school_partnership_id
    attribute :delivery_partner_api_id

    validate :school_partnership_exists
    validate :delivery_partner_is_eligible_for_school_partnership, if: -> { errors.empty? }

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

    def framework_agreement
      @framework_agreement ||= school_partnership&.framework_agreement
    end

    def lead_provider_delivery_partnership
      return unless framework_agreement && delivery_partner

      @lead_provider_delivery_partnership ||= delivery_partner.lead_provider_delivery_partnerships.find_by(framework_agreement:, delivery_partner:)
    end

    def school_partnership_exists
      return errors.add(:school_partnership_id, "Enter a '#/school_partnership_id'.") if school_partnership_id.blank?

      errors.add(:school_partnership_id, "The '#/school_partnership_id' you have entered is invalid. Check partnership details and try again.") unless school_partnership
    end

    def delivery_partner_is_eligible_for_school_partnership
      return errors.add(:delivery_partner_api_id, "Enter a '#/delivery_partner_api_id'.") if delivery_partner_api_id.blank?
      return errors.add(:delivery_partner_api_id, "The '#/delivery_partner_api_id' you have entered is invalid. Check delivery partner details and try again.") unless delivery_partner
      return errors.add(:delivery_partner_api_id, "The entered delivery partner is not recognised to be working in partnership with you for the given contract period. Contact the DfE for more information.") unless lead_provider_delivery_partnership

      errors.add(:delivery_partner_api_id, "We are unable to process this request. You are already confirmed to be in partnership with the entered delivery partner. Contact the DfE for support.") if matching_school_partnership_exists?
    end

    def matching_school_partnership_exists?
      school_partnership.school.school_partnerships.exists?(lead_provider_delivery_partnership:)
    end
  end
end
