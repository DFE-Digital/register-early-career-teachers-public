module SandboxSeedData
  class LeadProviders < Base
    DATA = {
      "Ambition Institute" => 2021..2025,
      "Best Practice Network" => 2021..2024,
      "Capita" => 2021..2022,
      "Teach First" => 2021..2025,
      "National Institute of Teaching" => 2021..2025,
      "Education Development Trust" => 2021..2025,
      "UCL Institute of Education" => 2021..2025,
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("lead providers")

      DATA.each.with_index do |(name, active_years), index|
        lead_provider = LeadProvider.find_or_create_by!(name:)

        active_years.each do |year|
          contract_period = ContractPeriod.find_by!(year:)
          ActiveLeadProvider.find_or_create_by!(contract_period:, lead_provider:)
        end

        log_seed_info("#{Colourize.text(name, colour(index))} (#{active_years.to_a.join(', ')})")
      end
    end

  private

    def colour(index)
      Colourize::COLOURS.keys[index % Colourize::COLOURS.size]
    end
  end
end
