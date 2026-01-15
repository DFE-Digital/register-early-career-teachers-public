namespace :api_seed_data do
  desc "Generate seed data for the sandbox environment"
  task generate: :environment do
    seeds = [
      APISeedData::ContractPeriods,
      APISeedData::LeadProviders,
      APISeedData::SchedulesAndMilestones,
      APISeedData::Statements,
      APISeedData::Schools,
      APISeedData::DeliveryPartners,
      APISeedData::LeadProviderDeliveryPartnerships,
      APISeedData::SchoolPartnerships,
      APISeedData::TeachersWithHistories,
      APISeedData::UnfundedMentors,
      APISeedData::TeachersWithChangeSchedule,
      APISeedData::Teachers::SchoolTransfers,
      APISeedData::Declarations,
    ]

    # These need to run last to avoid earlier seeds messing up the specific scenarios.
    seeds += [
      APISeedData::SchoolScenarios
    ]

    if Rails.env.development? || Rails.env.review? || Rails.env.staging?
      seeds += [
        APISeedData::APITokens,
        APISeedData::ParityChecks,
      ]
    end

    DeclarativeUpdates.skip(:metadata) do
      seeds.each do |seed_class|
        seed = seed_class.new
        seed.plant
      end
    end

    Metadata::Manager.refresh_all_metadata!(async: false)
  end
end
