module APISeedData
  class LeadProviders < Base
    DATA = {
      "Ambition Institute" => {
        contract_period_years: 2021..2025,
        vat_registered: true,
        short_name: "ambition",
      },
      "Best Practice Network" => {
        contract_period_years: 2021..2024,
        vat_registered: true,
        short_name: "bpn",
      },
      "Capita" => {
        contract_period_years: 2021..2022,
        vat_registered: true,
        short_name: "capita",
      },
      "Teach First" => {
        contract_period_years: 2021..2025,
        vat_registered: false,
        short_name: "tf",
      },
      "National Institute of Teaching" => {
        contract_period_years: 2021..2025,
        vat_registered: false,
        short_name: "niot",
      },
      "Education Development Trust" => {
        contract_period_years: 2021..2025,
        vat_registered: true,
        short_name: "edt",
      },
      "UCL Institute of Education" => {
        contract_period_years: 2021..2025,
        vat_registered: true,
        short_name: "ucl",
      },
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("lead providers")

      DATA.each.with_index do |(name, attributes), index|
        lead_provider = FactoryBot.create(:lead_provider, name:, short_name: attributes[:short_name], vat_registered: attributes[:vat_registered])

        attributes[:contract_period_years].each do |year|
          contract_period = ContractPeriod.find_by!(year:)
          FactoryBot.create(:framework_agreement, contract_period:, lead_provider:)
        end

        log_seed_info("#{Colourize.text(name, colour(index))} (#{attributes[:contract_period_years].to_a.join(', ')})")
      end
    end

  private

    def colour(index)
      Colourize::COLOURS.keys[index % Colourize::COLOURS.size]
    end
  end
end
