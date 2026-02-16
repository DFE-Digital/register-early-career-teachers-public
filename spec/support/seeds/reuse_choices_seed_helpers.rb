module Seeds
  module ReuseChoicesSeedHelpers
    BASE_URN = Seeds::ReuseChoices::BASE_URN

    def run_reuse_choices_seed!(contract_period_year:)
      ensure_test_appropriate_body!
      Seeds::ReuseChoices.new(contract_period_year:).call
    end

    def reuse_choices_urns
      (BASE_URN..(BASE_URN + 16)).to_a
    end

    def reuse_school(offset:)
      School.find_by!(urn: BASE_URN + offset)
    end

    def reuse_reference_lead_provider
      find_by_name!(LeadProvider, Seeds::ReuseChoices::LEAD_PROVIDER_REUSABLE_NAME)
    end

    def reuse_reference_lead_provider_not_available
      find_by_name!(LeadProvider, Seeds::ReuseChoices::LEAD_PROVIDER_NOT_AVAILABLE_IN_TARGET_YEAR_NAME)
    end

    def reuse_reference_delivery_partner
      find_by_name!(DeliveryPartner, Seeds::ReuseChoices::DELIVERY_PARTNER_REUSABLE_NAME)
    end

    def reuse_reference_delivery_partner_not_reusable
      find_by_name!(DeliveryPartner, Seeds::ReuseChoices::DELIVERY_PARTNER_NOT_REUSABLE_NAME)
    end

    def reuse_reference_appropriate_body
      AppropriateBody.find_by(name: Seeds::ReuseChoices::PREFERRED_APPROPRIATE_BODY_NAME) ||
        AppropriateBody.first ||
        raise("Expected an AppropriateBody to exist for seed scenarios")
    end

    def reuse_choices_schedule_identifier
      Seeds::ReuseChoices::SCHEDULE_IDENTIFIER
    end

    def scenario_ect_period_for_school!(school:, previous_year:)
      school.ect_at_school_periods.find_by!(
        started_on: Date.new(previous_year, 9, 1),
        finished_on: Date.new(previous_year + 1, 7, 31)
      )
    end

    def scenario_provider_led_training_period_for_school!(school:, previous_year:)
      ect_at_school_period = scenario_ect_period_for_school!(school:, previous_year:)

      TrainingPeriod.find_by!(
        ect_at_school_period:,
        training_programme: "provider_led",
        started_on: ect_at_school_period.started_on
      )
    end

    def target_year_partnership_exists?(school:, contract_period_year:, lead_provider:, delivery_partner:)
      SchoolPartnership
        .joins(lead_provider_delivery_partnership: [{ active_lead_provider: :contract_period }, :delivery_partner])
        .where(school:)
        .where(contract_periods: { year: contract_period_year })
        .where(active_lead_providers: { lead_provider_id: lead_provider.id })
        .where(delivery_partners: { id: delivery_partner.id })
        .exists?
    end

    def target_year_active_lead_provider_exists?(contract_period_year:, lead_provider:)
      ActiveLeadProvider
        .joins(:contract_period)
        .where(lead_provider:)
        .where(contract_periods: { year: contract_period_year })
        .exists?
    end

  private

    def find_by_name!(klass, name)
      klass.find_by!(name:)
    end

    def ensure_test_appropriate_body!
      return if AppropriateBody.exists?

      FactoryBot.create(:appropriate_body)
    end
  end
end
