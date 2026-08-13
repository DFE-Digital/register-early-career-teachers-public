module APISeedData
  class Contracts < Base
    def plant
      return unless plantable?

      log_plant_info("contracts")

      framework_agreements
        .order("lead_providers.name ASC", contract_period_year: :asc)
        .group_by(&:lead_provider)
        .each do |lead_provider, framework_agreements|
          log_seed_info("#{lead_provider.name} contracts", indent: 0)

          framework_agreements.map do |framework_agreement|
            number_of_contracts = Faker::Number.between(from: 1, to: 3)
            contracts = if framework_agreement.contract_period.mentor_funding_enabled?
                          FactoryBot.create_list(:contract, number_of_contracts, :for_ittecf_ectp, framework_agreement:)
                        else
                          FactoryBot.create_list(:contract, number_of_contracts, :for_ecf, framework_agreement:)
                        end

            describe_contracts(framework_agreement, contracts)
          end
        end
    end

  private

    def describe_contracts(framework_agreement, contracts)
      colour = framework_agreement.contract_period.mentor_funding_enabled? ? :magenta : :cyan
      contracts_summary = contracts
        .group_by(&:contract_type)
        .map { |type, contracts| "#{contracts.size} #{type.to_s.humanize.upcase}" }
        .join(", ")

      log_seed_info("Contracts for #{framework_agreement.contract_period.year}: #{contracts_summary}", indent: 2, colour:)
    end
  end
end
