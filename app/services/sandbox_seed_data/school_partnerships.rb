module SandboxSeedData
  class SchoolPartnerships < Base
    SCHOOL_PARTNERSHIPS_PER_ACTIVE_LEAD_PROVIDER = 100
    SAME_SCHOOL_DIFFERENT_DELIVERY_PARTNER_PER_ACTIVE_LEAD_PROVIDER = 5

    def plant
      return unless plantable?

      log_plant_info("school partnerships")

      ActiveLeadProvider.find_each do |active_lead_provider|
        SCHOOL_PARTNERSHIPS_PER_ACTIVE_LEAD_PROVIDER.times do |n|
          school = create_school_partnerships(active_lead_provider)

          if n < SAME_SCHOOL_DIFFERENT_DELIVERY_PARTNER_PER_ACTIVE_LEAD_PROVIDER
            create_school_partnerships(active_lead_provider, school:)
          end
        end
      end
    end

  private

    def create_school_partnerships(active_lead_provider, school: nil)
      school ||= find_available_school(active_lead_provider)
      delivery_partner = find_available_delivery_partner(active_lead_provider)

      lead_provider_delivery_partnership = find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
      school_partnership = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)

      log_seed_info("#{school_partnership.school.name} -> #{school_partnership.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)

      school
    end

    def find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
      LeadProviderDeliveryPartnership.find_by(active_lead_provider:, delivery_partner:) ||
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
    end

    def find_available_school(active_lead_provider)
      existing_school_ids = LeadProviderDeliveryPartnership.find_by(active_lead_provider:).school_partnerships.pluck(:school_id)
      School.where.not(id: existing_school_ids).order("RANDOM()").first!
    end

    def find_available_delivery_partner(active_lead_provider)
      existing_delivery_partner_ids = active_lead_provider.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)
      DeliveryPartner.where.not(id: existing_delivery_partner_ids).order("RANDOM()").first!
    end
  end
end
