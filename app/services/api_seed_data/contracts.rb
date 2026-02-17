module APISeedData
  class Contracts < Base
    def plant
      return unless plantable?

      log_plant_info("contracts")

      ActiveLeadProvider
        .includes(:lead_provider, :contract_period)
        .order("lead_providers.name ASC", contract_period_year: :asc)
        .group_by(&:lead_provider)
        .each do |lead_provider, active_lead_providers|
          log_seed_info("#{lead_provider.name} contracts", indent: 0)

          active_lead_providers.map do |active_lead_provider|
            number_of_contracts = Faker::Number.between(from: 1, to: 3)
            contracts = if active_lead_provider.contract_period.mentor_funding_enabled?
                          FactoryBot.create_list(:contract, number_of_contracts, :for_ittecf_ectp, active_lead_provider:)
                        else
                          FactoryBot.create_list(:contract, number_of_contracts, :for_ecf, active_lead_provider:)
                        end

            describe_contracts(active_lead_provider, contracts)
          end
      end
    end

  protected

    def plantable?
      super && Contract.none?
    end

  private

    def describe_contracts(active_lead_provider, contracts)
      colour = active_lead_provider.contract_period.mentor_funding_enabled? ? :magenta : :cyan
      contracts_summary = contracts
        .group_by(&:contract_type)
        .map { |type, contracts| "#{contracts.size} #{type.to_s.humanize.upcase}" }
        .join(", ")

      log_seed_info("Contracts for #{active_lead_provider.contract_period.year}: #{contracts_summary}", indent: 2, colour:)
    end
  end
end
