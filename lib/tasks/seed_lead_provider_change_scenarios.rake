namespace :seed do
  desc "Seed lead provider change scenarios"
  task lead_provider_change_scenarios: :environment do
    require Rails.root.join("db/seeds/support/seeds/lead_provider_change_scenarios")

    Seeds::LeadProviderChangeScenarios.new.call
  end
end
