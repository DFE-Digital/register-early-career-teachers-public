namespace :api_seed_data do
  desc "Generate seed data for the sandbox environment"
  task generate: :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    seeds = [
      APISeedData::ContractPeriods,
      APISeedData::LeadProviders,
      APISeedData::SchedulesAndMilestones,
      APISeedData::Contracts,
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

    if Rails.env.sandbox?
      # These need to run last to avoid earlier seeds messing up the specific scenarios.
      # They are specific scenarios lead providers asked for, so we only run them on sandbox.
      seeds += [
        APISeedData::SchoolScenarios,
        APISeedData::ParticipantScenarios,
        APISeedData::ECTScenarios,
        APISeedData::ECTBecomeMentorScenarios,
        APISeedData::MentorScenarios,
        APISeedData::SITBecomeMentorScenarios,
        APISeedData::ECTParticipantActionScenarios,
        APISeedData::ECTDeclarationScenarios,
      ]
    end

    if Rails.env.development? || Rails.env.review? || Rails.env.staging?
      seeds += [
        APISeedData::APITokens
      ]
    end

    DeclarativeUpdates.skip(:metadata) do
      seeds.each do |seed_class|
        seed = seed_class.new(verbose: false)
        seed.plant
      end
    end

    Metadata::Manager.refresh_all_metadata!(async: !Rails.env.development?)
  end
end
