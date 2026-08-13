module APISeedData
  class LeadProviderDeliveryPartnerships < Base
    DELIVERY_PARTNERS_PER_LEAD_PROVIDER = 15
    SHARED_DELIVERY_PARTNERS_PER_LEAD_PROVIDER = 3
    APPLICABLE_CONTRACT_PERIOD_YEARS = (2021..2025).to_a.freeze
    COL_WIDTHS = {
      lead_provider_name: 40,
      delivery_partner_name: 40,
      year: 6,
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("lead provider delivery partnerships")

      framework_agreements.find_each do |framework_agreement|
        DELIVERY_PARTNERS_PER_LEAD_PROVIDER.times { create_lead_provider_delivery_partnership(framework_agreement) }
        SHARED_DELIVERY_PARTNERS_PER_LEAD_PROVIDER.times do |index|
          delivery_partner = shared_delivery_partner(index)
          create_lead_provider_delivery_partnership(framework_agreement, delivery_partner:)
        end
      end

      log_delivery_partnerships_info
      log_shared_delivery_partner_info
    end

  private

    def log_shared_delivery_partner_info
      log_seed_info("Shared delivery partners", indent: 2, blank_lines_before: 1)

      SHARED_DELIVERY_PARTNERS_PER_LEAD_PROVIDER.times do |index|
        delivery_partner = shared_delivery_partner(index)

        delivery_partner_name = delivery_partner.name.ljust(COL_WIDTHS[:delivery_partner_name])
        delivery_partner_api_id = Colourize.text(delivery_partner.api_id, :green)

        log_seed_info("#{delivery_partner_name}(#{delivery_partner_api_id})", indent: 4)
      end
    end

    def log_delivery_partnerships_info
      lead_providers.find_each do |lead_provider|
        log_header_info(lead_provider)
        log_row_info(lead_provider)
      end
    end

    def log_header_info(lead_provider)
      name_header = lead_provider.name.ljust(COL_WIDTHS[:lead_provider_name])
      years_header = APPLICABLE_CONTRACT_PERIOD_YEARS.map { |year| year.to_s.rjust(COL_WIDTHS[:year]) }.join

      log_seed_info(name_header + years_header, indent: 2)
    end

    def log_row_info(lead_provider)
      count_by_contract_period_year = LeadProviderDeliveryPartnership
        .joins(framework_agreement: :lead_provider)
        .where(framework_agreement: { lead_provider: })
        .group("framework_agreement.contract_period_year")
        .order("framework_agreement.contract_period_year")
        .count

      name_space = " " * COL_WIDTHS[:lead_provider_name]
      years_info = APPLICABLE_CONTRACT_PERIOD_YEARS.map do |year|
        count = count_by_contract_period_year[year] || 0
        format_year_count(count)
      end

      log_seed_info(name_space + years_info.join, indent: 2)
    end

    def format_year_count(count)
      coloured_count = if count.positive?
                         Colourize.text(count, :blue)
                       else
                         Colourize.text(0, :red)
                       end

      # The colourizing characters affect the length so offset the rjust.
      offset = coloured_count.length - count.to_s.length
      coloured_count.rjust(COL_WIDTHS[:year] + offset)
    end

    def create_lead_provider_delivery_partnership(framework_agreement, delivery_partner: nil)
      delivery_partner ||= find_random_available_delivery_partner(framework_agreement)

      return if framework_agreement.lead_provider_delivery_partnerships.exists?(delivery_partner:)

      FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:, delivery_partner:)
    end

    def find_random_available_delivery_partner(framework_agreement)
      existing_delivery_partners = framework_agreement.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)

      DeliveryPartner
        .where.not(id: existing_delivery_partners)
        .order("RANDOM()")
        .first
    end

    def shared_delivery_partner(index)
      DeliveryPartner.order(:name).offset(index).limit(1).first
    end

    def framework_agreements
      super.where(contract_period: relevant_contract_periods)
    end

    def relevant_contract_periods
      ContractPeriod.where(year: APPLICABLE_CONTRACT_PERIOD_YEARS)
    end
  end
end
