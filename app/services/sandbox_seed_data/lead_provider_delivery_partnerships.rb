module SandboxSeedData
  class LeadProviderDeliveryPartnerships < Base
    DELIVERY_PARTNERS_PER_LEAD_PROVIDER = 30
    SHARED_DELIVERY_PARTNERS_PER_LEAD_PROVIDER = 5
    APPLICABLE_CONTRACT_PERIOD_YEARS = (2021..2025).to_a.freeze
    COL_WIDTHS = {
      lead_provider_name: 40,
      delivery_partner_name: 40,
      year: 6,
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("lead provider delivery partnerships")

      active_lead_providers.find_each do |active_lead_provider|
        DELIVERY_PARTNERS_PER_LEAD_PROVIDER.times { create_lead_provider_delivery_partnership(active_lead_provider) }
        SHARED_DELIVERY_PARTNERS_PER_LEAD_PROVIDER.times do |index|
          delivery_partner = shared_delivery_partner(index)
          create_lead_provider_delivery_partnership(active_lead_provider, delivery_partner:)
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
      LeadProvider.find_each do |lead_provider|
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
        .joins(active_lead_provider: :lead_provider)
        .where(active_lead_provider: { lead_provider: })
        .group("active_lead_provider.contract_period_year")
        .order("active_lead_provider.contract_period_year")
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

    def create_lead_provider_delivery_partnership(active_lead_provider, delivery_partner: nil)
      delivery_partner ||= find_random_available_delivery_partner(active_lead_provider)

      return if active_lead_provider.lead_provider_delivery_partnerships.exists?(delivery_partner:)

      FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
    end

    def find_random_available_delivery_partner(active_lead_provider)
      existing_delivery_partners = active_lead_provider.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)

      DeliveryPartner
        .where.not(id: existing_delivery_partners)
        .order("RANDOM()")
        .first
    end

    def shared_delivery_partner(index)
      DeliveryPartner.order(:name).offset(index).limit(1).first
    end

    def active_lead_providers
      ActiveLeadProvider.where(contract_period: relevant_contract_periods)
    end

    def relevant_contract_periods
      ContractPeriod.where(year: APPLICABLE_CONTRACT_PERIOD_YEARS)
    end
  end
end
