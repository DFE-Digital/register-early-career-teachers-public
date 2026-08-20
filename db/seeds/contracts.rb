def describe_contracts(framework_agreement, contracts)
  colour = framework_agreement.contract_period.mentor_funding_enabled? ? :magenta : :cyan
  contracts_summary = contracts
    .group_by(&:contract_type)
    .map { |type, contracts|
      "#{contracts.size} #{type.to_s.humanize.upcase} with #{contracts.first.banded_fee_structure.band_terms.size} band terms"
    }
    .join(", ")
  print_seed_info("Contracts for #{framework_agreement.contract_period.year}: #{contracts_summary}", indent: 2, colour:)
end

FrameworkAgreement
  .includes(:lead_provider, :contract_period)
  .order("lead_providers.name ASC", contract_period_year: :asc)
  .group_by(&:lead_provider)
  .each do |lead_provider, framework_agreements|
    print_seed_info("#{lead_provider.name} contracts", indent: 0)

    framework_agreements.map do |framework_agreement|
      number_of_contracts = Faker::Number.between(from: 1, to: 3)
      contracts =
        if framework_agreement.contract_period.mentor_funding_enabled? &&
            framework_agreement.contract_period.year > 2024
          FactoryBot.create_list(:contract, number_of_contracts, :for_ittecf_ectp,
                                 framework_agreement:)
        else
          FactoryBot.create_list(:contract, number_of_contracts, :for_ecf,
                                 framework_agreement:)
        end

      contracts.each do |contract|
        next unless contract.banded_fee_structure

        contract.framework_agreement.bands.each do |band|
          contract.banded_fee_structure.band_terms.find_or_create_by!(band:) do |term|
            term.fee_per_declaration = Faker::Number.between(from: 20, to: 200)
            term.output_fee_ratio = 0.8
            term.service_fee_ratio = 0.2
          end
        end
      end

      describe_contracts(framework_agreement, contracts)
    end
  end
