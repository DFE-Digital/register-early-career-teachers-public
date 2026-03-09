module APISeedData
  class SchoolPartnerships < Base
    SCHOOL_PARTNERSHIPS_PER_ACTIVE_LEAD_PROVIDER = 30
    SAME_SCHOOL_DIFFERENT_DELIVERY_PARTNER_PER_ACTIVE_LEAD_PROVIDER = 5
    PUPIL_PREMIUM_UPLIFT_RATIO = 0.15
    SPARSITY_UPLIFT_RATIO = 0.20

    def plant
      return unless plantable?

      log_plant_info("school partnerships")

      active_lead_providers.find_each do |active_lead_provider|
        SCHOOL_PARTNERSHIPS_PER_ACTIVE_LEAD_PROVIDER.times do
          school = create_school_partnership(active_lead_provider)
          set_school_funding_eligibility_for(school, active_lead_provider)
        end

        schools = select_existing_schools(active_lead_provider)
        schools.each do |school|
          create_school_partnership(active_lead_provider, school:)
        end
      end
    end

  private

    def create_school_partnership(active_lead_provider, school: nil)
      school ||= find_available_school(active_lead_provider)
      return unless school

      delivery_partner = find_available_delivery_partner(active_lead_provider)
      return unless delivery_partner

      lead_provider_delivery_partnership = find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
      school_partnership = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)

      log_seed_info("#{school_partnership.school.name} -> #{school_partnership.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)

      school
    end

    def find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
      LeadProviderDeliveryPartnership.find_by(active_lead_provider:, delivery_partner:) ||
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
    end

    def school_partnerships(active_lead_provider)
      SchoolPartnership
        .includes(:lead_provider_delivery_partnership)
        .where(lead_provider_delivery_partnership: { active_lead_provider: })
    end

    def find_available_school(active_lead_provider)
      existing_school_ids = school_partnerships(active_lead_provider).pluck(:school_id)

      School.where.not(id: existing_school_ids).order("RANDOM()").first
    end

    def select_existing_schools(active_lead_provider)
      school_partnerships(active_lead_provider)
        .order("RANDOM()")
        .first(SAME_SCHOOL_DIFFERENT_DELIVERY_PARTNER_PER_ACTIVE_LEAD_PROVIDER)
        .map(&:school)
    end

    def find_available_delivery_partner(active_lead_provider)
      existing_delivery_partner_ids = active_lead_provider.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)

      DeliveryPartner.where.not(id: existing_delivery_partner_ids).order("RANDOM()").first
    end

    def set_school_funding_eligibility_for(school, active_lead_provider)
      return unless school

      FactoryBot.create(:school_funding_eligibility,
                        sparsity_uplift: Faker::Boolean.boolean(true_ratio: SPARSITY_UPLIFT_RATIO),
                        pupil_premium_uplift: Faker::Boolean.boolean(true_ratio: PUPIL_PREMIUM_UPLIFT_RATIO),
                        contract_period: active_lead_provider.contract_period,
                        school:)
    end
  end
end
