namespace :sandbox_seed_data do
  desc "Generate seed data for the sandbox environment"
  task generate: :environment do
    seeds = [
      SandboxSeedData::ContractPeriods,
      SandboxSeedData::LeadProviders,
      SandboxSeedData::Statements,
      SandboxSeedData::Schools,
    ]

    seeds.each do |seed_class|
      seed = seed_class.new
      seed.plant
    end
  end
end
