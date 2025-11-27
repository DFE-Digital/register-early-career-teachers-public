module ReusablePartnershipHelpers
  ReusablePartnershipContext = Struct.new(
    :school,
    :current_contract_period,
    :previous_school_partnership,
    :last_chosen_lead_provider,
    :previous_year_delivery_partner,
    keyword_init: true
  )

  def build_school_with_reusable_provider_led_partnership
    current_year  = Time.zone.today.year
    previous_year = current_year - 1

    current_contract_period  = FactoryBot.create(:contract_period, :with_schedules, year: current_year)
    previous_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: previous_year)

    lead_provider    = FactoryBot.create(:lead_provider, name: "Orange Institute")
    delivery_partner = FactoryBot.create(:delivery_partner, name: "Jaskolski College Delivery Partner 1")

    previous_year_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period: previous_contract_period
    )

    FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period: current_contract_period
    )

    previous_year_delivery_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: previous_year_active_lead_provider,
      delivery_partner:
    )

    school = FactoryBot.create(
      :school,
      :state_funded,
      :provider_led_last_chosen,
      :teaching_school_hub_ab_last_chosen,
      last_chosen_lead_provider: lead_provider
    )

    previous_school_partnership = FactoryBot.create(
      :school_partnership,
      school:,
      lead_provider_delivery_partnership: previous_year_delivery_partnership
    )

    ReusablePartnershipContext.new(
      school:,
      current_contract_period:,
      previous_school_partnership:,
      last_chosen_lead_provider: lead_provider,
      previous_year_delivery_partner: delivery_partner
    )
  end
end
