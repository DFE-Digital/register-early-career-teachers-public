module APISeedData
  class SchoolPartnerships < Base
    SCHOOL_PARTNERSHIPS_PER_FRAMEWORK_AGREEMENT = 15
    SAME_SCHOOL_DIFFERENT_DELIVERY_PARTNER_PER_FRAMEWORK_AGREEMENT = 5

    def plant
      return unless plantable?

      log_plant_info("school partnerships")

      framework_agreements.find_each do |framework_agreement|
        SCHOOL_PARTNERSHIPS_PER_FRAMEWORK_AGREEMENT.times do
          create_school_partnership(framework_agreement)
        end

        schools = select_existing_schools(framework_agreement)
        schools.each do |school|
          create_school_partnership(framework_agreement, school:)
        end
      end
    end

  private

    def create_school_partnership(framework_agreement, school: nil)
      school ||= find_available_school(framework_agreement)
      return unless school

      delivery_partner = find_available_delivery_partner(framework_agreement)
      return unless delivery_partner

      lead_provider_delivery_partnership = find_or_create_lead_provider_delivery_partnership(framework_agreement:, delivery_partner:)
      school_partnership = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)

      log_seed_info("#{school_partnership.school.name} -> #{school_partnership.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)

      school
    end

    def find_or_create_lead_provider_delivery_partnership(framework_agreement:, delivery_partner:)
      LeadProviderDeliveryPartnership.find_by(framework_agreement:, delivery_partner:) ||
        FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:, delivery_partner:)
    end

    def school_partnerships(framework_agreement)
      SchoolPartnership
        .includes(:lead_provider_delivery_partnership)
        .where(lead_provider_delivery_partnership: { framework_agreement: })
    end

    def find_available_school(framework_agreement)
      existing_school_ids = school_partnerships(framework_agreement).pluck(:school_id)

      School.where.not(id: existing_school_ids).order("RANDOM()").first
    end

    def select_existing_schools(framework_agreement)
      school_partnerships(framework_agreement)
        .order("RANDOM()")
        .first(SAME_SCHOOL_DIFFERENT_DELIVERY_PARTNER_PER_FRAMEWORK_AGREEMENT)
        .map(&:school)
    end

    def find_available_delivery_partner(framework_agreement)
      existing_delivery_partner_ids = framework_agreement.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)

      DeliveryPartner.where.not(id: existing_delivery_partner_ids).order("RANDOM()").first
    end
  end
end
