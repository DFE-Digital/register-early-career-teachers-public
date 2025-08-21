# TODO: error messages are currently consistent with ECF, however we want them to use RECT
# terminology in the service and will look to map between them somehow in a future PR.
module SchoolPartnerships
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider_id
    attribute :contract_period_year
    attribute :school_api_id
    attribute :delivery_partner_api_id

    validates :contract_period_year, presence: { message: "Enter a '#/cohort'." }
    validates :school_api_id, presence: { message: "Enter a '#/school_id'." }
    validates :lead_provider_id, presence: { message: "Enter a '#/lead_provider_id'." }
    validates :delivery_partner_api_id, presence: { message: "Enter a '#/delivery_partner_id'." }
    validate :enabled_contract_period_year_exists
    validate :lead_provider_exists
    validate :school_exists
    validate :school_is_not_cip_only
    validate :school_is_eligible
    validate :delivery_partner_exists
    validate :lead_provider_delivery_partnership_exists
    validate :school_partnership_does_not_already_exists
    validate :not_school_led

    def create
      return false unless valid?

      SchoolPartnership.create!(
        school:,
        lead_provider_delivery_partnership:
      ).tap do |school_partnership|
        Events::Record.record_school_partnership_created_event!(author: Events::LeadProviderAuthor.new, school_partnership:)
      end
    end

  private

    def contract_period
      @contract_period ||= ContractPeriod.enabled.find_by(year: contract_period_year) if contract_period_year
    end

    def lead_provider
      @lead_provider ||= LeadProvider.find_by(id: lead_provider_id) if lead_provider_id
    end

    def school
      @school ||= School.joins(:gias_school).find_by(gias_school: { api_id: school_api_id }) if school_api_id
    end

    def delivery_partner
      @delivery_partner ||= DeliveryPartner.find_by(api_id: delivery_partner_api_id) if delivery_partner_api_id
    end

    def enabled_contract_period_year_exists
      errors.add(:contract_period_year, "The '#/cohort' you have entered is invalid. Check cohort details and try again.") unless contract_period
    end

    def lead_provider_exists
      errors.add(:lead_provider_id, "Enter a '#/lead_provider_id'.") unless lead_provider
    end

    def school_exists
      errors.add(:school_api_id, "The '#/school_id' you have entered is invalid. Check school details and try again. Contact the DfE for support if you are unable to find the '#/school_id'.") unless school
    end

    def school_is_not_cip_only
      errors.add(:school_api_id, "The school you have entered has not registered to deliver DfE-funded training. Contact the school for more information.") if school&.eligible_for_cip?
    end

    def school_is_eligible
      errors.add(:school_api_id, "The school you have entered is currently ineligible for DfE funding. Contact the school for more information.") unless school&.eligible_for_fip?
    end

    def school_partnership_does_not_already_exists
      return unless school && active_lead_provider

      existing_school_partnership = school
        .school_partnerships
        .joins(:lead_provider_delivery_partnership)
        .exists?(lead_provider_delivery_partnerships: { active_lead_provider: })

      errors.add(:school_api_id, "You are already in a confirmed partnership with this school for the entered cohort.") if existing_school_partnership
    end

    def delivery_partner_exists
      errors.add(:delivery_partner_api_id, "The '#/delivery_partner_id' you have entered is invalid. Check delivery partner details and try again.") unless delivery_partner
    end

    def active_lead_provider
      return unless lead_provider && contract_period

      @active_lead_provider ||= lead_provider.active_lead_providers.find_by(contract_period:)
    end

    def lead_provider_delivery_partnership
      return unless active_lead_provider && delivery_partner

      @lead_provider_delivery_partnership ||= delivery_partner.lead_provider_delivery_partnerships.find_by(active_lead_provider:, delivery_partner:)
    end

    def lead_provider_delivery_partnership_exists
      return unless lead_provider && delivery_partner

      errors.add(:delivery_partner_api_id, "The entered delivery partner is not recognised to be working in partnership with you for the given cohort. Contact the DfE for more information.") unless lead_provider_delivery_partnership
    end

    def metadata
      return unless school && contract_period

      @metadata ||= school.contract_period_metadata.find_by(contract_period:)
    end

    def not_school_led
      return unless metadata&.induction_programme_choice == "school_led"

      errors.add(:induction_programme_choice, "The school you have entered has not yet confirmed they will deliver DfE-funded training. Contact the school for more information.")
    end
  end
end
