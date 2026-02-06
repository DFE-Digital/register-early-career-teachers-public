module APISeedData
  class LeadProviders < Base
    DATA = {
      "Ambition Institute" => {
        contract_period_years: 2021..2025,
        vat_registered: true,
      },
      "Best Practice Network" => {
        contract_period_years: 2021..2024,
        vat_registered: true,
      },
      "Capita" => {
        contract_period_years: 2021..2022,
        vat_registered: true,
      },
      "Teach First" => {
        contract_period_years: 2021..2025,
        vat_registered: false,
      },
      "National Institute of Teaching" => {
        contract_period_years: 2021..2025,
        vat_registered: false,
      },
      "Education Development Trust" => {
        contract_period_years: 2021..2025,
        vat_registered: true,
      },
      "UCL Institute of Education" => {
        contract_period_years: 2021..2025,
        vat_registered: true,
      },
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("lead providers")

      DATA.each.with_index do |(name, attributes), index|
        lead_provider = FactoryBot.create(:lead_provider, name:, vat_registered: attributes[:vat_registered])

        attributes[:contract_period_years].each do |year|
          contract_period = ContractPeriod.find_by!(year:)
          FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
        end

        log_seed_info("#{Colourize.text(name, colour(index))} (#{attributes[:contract_period_years].to_a.join(', ')})")
      end
    end

  protected

    def plantable?
      super && LeadProvider.none?
    end

  private

    def colour(index)
      Colourize::COLOURS.keys[index % Colourize::COLOURS.size]
    end
  end
end
