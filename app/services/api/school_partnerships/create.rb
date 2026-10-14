module API::SchoolPartnerships
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider_id
    attribute :contract_period_year
    attribute :school_api_id
    attribute :delivery_partner_api_id

    validate :partnership_can_be_added_to_contract_period
    validate :school_is_eligible_for_partnership, if: -> { errors.empty? }
    validate :lead_provider_exists, if: -> { errors.empty? }
    validate :delivery_partnership_exists, if: -> { errors.empty? }

    def create
      return false unless valid?

      SchoolPartnerships::Create.new(
        author: Events::LeadProviderAPIAuthor.new(lead_provider:),
        school:,
        lead_provider_delivery_partnership:
      ).create
    end

  private

    def contract_period
      @contract_period ||= ContractPeriod.find_by(year: contract_period_year) if contract_period_year
    end

    def lead_provider
      @lead_provider ||= LeadProvider.find_by(id: lead_provider_id) if lead_provider_id
    end

    def school
      @school ||= School.find_by(api_id: school_api_id) if school_api_id
    end

    def delivery_partner
      @delivery_partner ||= DeliveryPartner.find_by(api_id: delivery_partner_api_id) if delivery_partner_api_id
    end

    def framework_agreement
      return unless lead_provider && contract_period

      @framework_agreement ||= lead_provider.framework_agreements.find_by(contract_period:)
    end

    def lead_provider_delivery_partnership
      return unless framework_agreement && delivery_partner

      @lead_provider_delivery_partnership ||= delivery_partner.lead_provider_delivery_partnerships.find_by(framework_agreement:, delivery_partner:)
    end

    def metadata
      return unless school && contract_period

      @metadata ||= school.contract_period_metadata.find_by(contract_period:)
    end

    def partnership_can_be_added_to_contract_period
      return errors.add(:contract_period_year, "Enter a '#/contract_period_year'.") if contract_period_year.blank?
      return errors.add(:contract_period_year, "The '#/contract_period_year' you have entered is invalid. Check contract period details and try again.") unless contract_period
      return errors.add(:contract_period_year, "You cannot create this partnership as the contract period is closed.") unless contract_period.enabled?

      errors.add(:contract_period_year, "You cannot create a partnership for a future contract period.") unless contract_period.started_on_or_before_today?
    end

    def school_is_eligible_for_partnership
      return errors.add(:school_api_id, "Enter a '#/school_api_id'.") if school_api_id.blank?
      return errors.add(:school_api_id, "The '#/school_api_id' you have entered is invalid. Check school details and try again. Contact the DfE for support if you are unable to find the '#/school_api_id'.") unless school
      return errors.add(:school_api_id, "The school you have entered is currently ineligible for DfE funding. Contact the school for more information.") unless school.eligible?
      return errors.add(:school_api_id, "You are already in a confirmed partnership with this school for the entered contract period.") if existing_school_partnership?

      errors.add(:school_api_id, "This school has only registered school-led teachers. Contact the school for more information.") if metadata&.induction_programme_choice == "school_led"
    end

    def lead_provider_exists
      errors.add(:lead_provider_id, "Enter a '#/lead_provider_id'.") unless lead_provider
    end

    def delivery_partnership_exists
      return errors.add(:delivery_partner_api_id, "Enter a '#/delivery_partner_api_id'.") if delivery_partner_api_id.blank?
      return errors.add(:delivery_partner_api_id, "The '#/delivery_partner_api_id' you have entered is invalid. Check delivery partner details and try again.") unless delivery_partner

      errors.add(:delivery_partner_api_id, "The entered delivery partner is not recognised to be working in partnership with you for the given contract period. Contact the DfE for more information.") unless lead_provider_delivery_partnership
    end

    def existing_school_partnership?
      return false unless framework_agreement

      school
        .school_partnerships
        .joins(:lead_provider_delivery_partnership)
        .exists?(lead_provider_delivery_partnerships: { framework_agreement: })
    end
  end
end
