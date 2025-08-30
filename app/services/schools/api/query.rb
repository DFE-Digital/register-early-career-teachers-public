module Schools::API
  class Query < Schools::Query
  protected

    def preload_associations(results)
      preloaded_results = results
        .strict_loading
        .includes(:gias_school, :contract_period_metadata, :lead_provider_contract_period_metadata)

      unless ignore?(filter: lead_provider_id)
        preloaded_results = preloaded_results
          .references(:metadata_schools_lead_providers_contract_periods)
          .where(metadata_schools_lead_providers_contract_periods: { lead_provider_id: })
      end

      unless ignore?(filter: contract_period_year)
        preloaded_results = preloaded_results
          .references(:metadata_schools_contract_periods, :metadata_schools_lead_providers_contract_periods)
          .where(metadata_schools_contract_periods: { contract_period_year: }, metadata_schools_lead_providers_contract_periods: { contract_period_year: })
      end

      preloaded_results
    end
  end
end
