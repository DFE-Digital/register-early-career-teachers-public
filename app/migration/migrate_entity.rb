class MigrateEntity
  # NOTE: the assumption is that the School records are present already having been populated via
  # the GIAS::Importer
  #

  attr_reader :logger

  def initialize(logger = Rails.logger)
    @logger = logger
  end

  # migrate a school partnership and all the dependencies
  def school_partnership(ecf_partnership:)
    # active lead provider (will add lead provider and all their contract periods)
    active_lead_provider(ecf_lead_provider: ecf_partnership.lead_provider)

    # need to migrate DP as it is a dependency
    Migrators::DeliveryPartner.new.migrate_one!(ecf_partnership.delivery_partner)

    # lead_provider_delivery_partnership
    ecf_lpdp = Migration::ProviderRelationship.find_by!(lead_provider: ecf_partnership.lead_provider,
                                                        delivery_partner: ecf_partnership.delivery_partner,
                                                        cohort: ecf_partnership.cohort)

    Migrators::LeadProviderDeliveryPartnership.new.migrate_one!(ecf_lpdp)

    # school_partnership
    Migrators::SchoolPartnership.new.migrate_one!(ecf_partnership)
  rescue StandardError => e
    logger.error(e.message)
  end

  # migrate a lead_provider and their active cohorts
  def active_lead_provider(ecf_lead_provider:)
    Migrators::LeadProvider.new.migrate_one!(ecf_lead_provider)

    alp = Data.define(:id, :start_year)
    ecf_lead_provider.cohorts.order(:start_year).each do |cohort|
      Migrators::ContractPeriod.new.migrate_one!(cohort)
      Migrators::ActiveLeadProvider.new.migrate_one!(alp.new(id: ecf_lead_provider.id, start_year: cohort.start_year))
    end
  rescue StandardError => e
    logger.error(e.message)
  end

  # migrate a teacher and their dependencies
  def teacher(trn:)
    teacher_profile = Migration::TeacherProfile
      .where(trn:)
      .joins(:participant_profiles)
      .eager_load(participant_profiles: [
        induction_records: [
          induction_programme: [
            school_cohort: :school,
            partnership: %i[
              lead_provider delivery_partner
            ]
          ]
        ]
      ]).first

    teacher = Migrators::Teacher.new.migrate_one!(teacher_profile)

    Migrators::ECTAtSchoolPeriod.new.migrate_one!(teacher_profile) if teacher_profile.participant_profiles.ect.any?
    Migrators::MentorAtSchoolPeriod.new.migrate_one!(teacher_profile) if teacher_profile.participant_profiles.mentor.any?

    teacher_profile.participant_profiles.each do |participant_profile|
      fetch_partnerships(participant_profile:).each do |ecf_partnership|
        # create school partnerships and all their dependencies
        school_partnership(ecf_partnership:)
      end

      next unless participant_profile.ect?

      fetch_mentors(participant_profile:).each do |ecf_mentor|
        # create mentors
        teacher(trn: ecf_mentor.teacher_profile.trn)
      end

      Migrators::MentorshipPeriod.new.migrate_one!(participant_profile)
    end

    Migrators::TrainingPeriod.new.migrate_one!(teacher_profile)

    teacher
  rescue StandardError => e
    logger.error(e.message)
  end


  # migrate a teacher and their dependencies
  def teacher_v2(trn:)
    teacher_profile = Migration::TeacherProfile
      .where(trn:)
      .joins(:participant_profiles)
      .eager_load(participant_profiles: [
        induction_records: [
          induction_programme: [
            school_cohort: :school,
            partnership: %i[
              lead_provider delivery_partner
            ]
          ]
        ]
      ]).first

    # dependencies
    teacher_profile.participant_profiles.each do |participant_profile|
      fetch_partnerships(participant_profile:).each do |ecf_partnership|
        # create school partnerships and all their dependencies
        school_partnership(ecf_partnership:)
      end

      next unless participant_profile.ect?

      fetch_mentors(participant_profile:).each do |ecf_mentor|
        # create mentors
        teacher_v2(trn: ecf_mentor.teacher_profile.trn)
      end

      # Migrators::MentorshipPeriod.new.migrate_one!(participant_profile)
    end

    Migrators::Teacher.new.migrate_one!(teacher_profile)

  rescue StandardError => e
    logger.error(e.message)
  end

private

  def fetch_partnerships(participant_profile:)
    Migration::Partnership.where(id: participant_profile.induction_records.joins(induction_programme: :partnership).select(:partnership_id))
  end

  def fetch_mentors(participant_profile:)
    Migration::ParticipantProfile.mentor.where(id: participant_profile.induction_records.select(:mentor_profile_id))
  end
end
