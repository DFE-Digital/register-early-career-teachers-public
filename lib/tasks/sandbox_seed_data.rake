namespace :sandbox_seed_data do
  desc "Generate seed data for the sandbox environment"
  task generate: :environment do
    seeds = [
      SandboxSeedData::ContractPeriods,
      SandboxSeedData::LeadProviders,
      SandboxSeedData::Statements,
      SandboxSeedData::Schools,
      SandboxSeedData::DeliveryPartners,
      SandboxSeedData::LeadProviderDeliveryPartnerships,
      SandboxSeedData::SchoolPartnerships,
      SandboxSeedData::Teachers,
      SandboxSeedData::TeacherHistories,
      SandboxSeedData::APITeachersWithHistories,
      SandboxSeedData::UnfundedMentors,
      SandboxSeedData::APITeachersWithChangeSchedule,
    ]

    DeclarativeUpdates.skip(:metadata) do
      seeds.each do |seed_class|
        seed = seed_class.new
        seed.plant
      end
    end

    Metadata::Manager.refresh_all_metadata!(async: true)
  end
end
