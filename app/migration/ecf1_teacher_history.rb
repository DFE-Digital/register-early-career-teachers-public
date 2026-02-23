class ECF1TeacherHistory
  using Migration::CompactWithIgnore

  class InvalidPeriodType < StandardError; end

  attr_accessor :user, :ect, :mentor, :participant_identity_updated_ats

  def initialize(user:, ect: nil, mentor: nil, participant_identity_updated_ats: [])
    @user = user
    @ect = ect
    @mentor = mentor
    @participant_identity_updated_ats = participant_identity_updated_ats
  end

  def self.build(teacher_profile:)
    user_record = teacher_profile.user
    ect_profile = teacher_profile.participant_profiles.detect(&:ect?)
    mentor_profile = teacher_profile.participant_profiles.detect(&:mentor?)

    user = User.new(
      trn: teacher_profile.trn,
      full_name: user_record.full_name,
      user_id: user_record.id,
      created_at: user_record.created_at,
      updated_at: user_record.updated_at
    )

    ect = build_ect_data(participant_profile: ect_profile) if ect_profile.present?

    mentor = build_mentor_data(participant_profile: mentor_profile) if mentor_profile.present?

    # Capture participant_identities updated_at timestamps for api_updated_at calculation
    participant_identity_updated_ats = user_record.participant_identities.map(&:updated_at)

    new(user:, ect:, mentor:, participant_identity_updated_ats:)
  end

  def self.build_appropriate_body(induction_record:)
    appropriate_body = induction_record.appropriate_body
    return if appropriate_body.blank?

    Types::AppropriateBodyData.new(ecf1_id: appropriate_body.id, name: appropriate_body.name)
  end

  def self.build_ect_data(participant_profile:)
    induction_records = build_induction_records(participant_profile:)

    ECT.new(
      participant_profile_id: participant_profile.id,
      created_at: participant_profile.created_at,
      updated_at: participant_profile.updated_at,
      induction_start_date: participant_profile.induction_start_date,
      induction_completion_date: participant_profile.induction_completion_date,
      pupil_premium_uplift: participant_profile.pupil_premium_uplift,
      sparsity_uplift: participant_profile.sparsity_uplift,
      payments_frozen_cohort_start_year: participant_profile.previous_payments_frozen_cohort_start_year,
      states: build_profile_states(participant_profile:),
      induction_records:,
      mentor_at_school_periods: SchoolMentorsForECT.new(induction_records:).mentor_at_school_periods
    )
  end

  # Build rows for all the induction records of the participant
  def self.build_induction_records(participant_profile:)
    participant_profile.induction_records.order(:start_date, :created_at).map do |induction_record|
      build_induction_record(induction_record:)
    end
  end

  def self.build_induction_record(induction_record:)
    InductionRecord.new(
      induction_record_id: induction_record.id,
      start_date: induction_record.start_date.to_date,
      end_date: induction_record.end_date&.to_date,
      created_at: induction_record.created_at,
      updated_at: induction_record.updated_at,
      cohort_year: induction_record.schedule.cohort.start_year,
      school: build_school_data(induction_record.induction_programme.school_cohort.school),
      schedule_info: build_schedule_info(schedule: induction_record.schedule),
      preferred_identity_email: induction_record.preferred_identity.email,
      mentor_profile_id: induction_record.mentor_profile_id,
      training_status: induction_record.training_status,
      induction_status: induction_record.induction_status,
      training_programme: induction_record.induction_programme.training_programme,
      training_provider_info: build_training_provider_info(induction_record:),
      appropriate_body: build_appropriate_body(induction_record:),
      start_timestamp: induction_record.start_date,
      end_timestamp: induction_record.end_date
    )
  end

  def self.build_school_data(school)
    Types::SchoolData.new(urn: school.urn, name: school.name, school_type_name: school_type_name_for(school))
  end

  def self.school_type_name_for(school)
    if school.respond_to?(:school_type_name)
      school.school_type_name
    elsif school.respond_to?(:type_name)
      school.type_name
    end
  end

  def self.build_mentor_data(participant_profile:)
    ero_check = EROMentorChecker.new(participant_profile:)

    Mentor.new(
      participant_profile_id: participant_profile.id,
      created_at: participant_profile.created_at,
      updated_at: participant_profile.updated_at,
      mentor_completion_date: participant_profile.mentor_completion_date,
      mentor_completion_reason: participant_profile.mentor_completion_reason,
      payments_frozen_cohort_start_year: participant_profile.previous_payments_frozen_cohort_start_year,
      states: build_profile_states(participant_profile:),
      induction_records: build_induction_records(participant_profile:),
      ero_mentor: ero_check.ero_mentor?,
      ero_declarations: ero_check.ero_mentor_with_declarations?
    )
  end

  def self.build_profile_states(participant_profile:)
    participant_profile.participant_profile_states.order(:created_at).map do |profile_state|
      ECF1TeacherHistory::ProfileState.new(
        state: profile_state.state,
        reason: profile_state.reason,
        created_at: profile_state.created_at,
        cpd_lead_provider_id: profile_state.cpd_lead_provider_id
      )
    end
  end

  def self.build_schedule_info(schedule:)
    Types::ScheduleInfo.new(
      schedule_id: schedule.id,
      identifier: schedule.schedule_identifier,
      name: schedule.name,
      cohort_year: schedule.cohort.start_year
    )
  end

  def self.build_training_provider_info(induction_record:)
    partnership = induction_record.induction_programme.partnership
    return if partnership.blank?

    TrainingProviderInfo.new(
      lead_provider_info: Types::LeadProviderInfo.new(
        ecf1_id: partnership.lead_provider.id,
        name: partnership.lead_provider.name
      ),
      delivery_partner_info: Types::DeliveryPartnerInfo.new(
        ecf1_id: partnership.delivery_partner.id,
        name: partnership.delivery_partner.name
      ),
      cohort_year: partnership.cohort.start_year
    )
  end

  def self.from_hash(hash)
    hash.compact_with_ignore!

    user = ECF1TeacherHistory::User.from_hash(hash.slice(:trn, :full_name, :user_id, :created_at, :updated_at).compact)
    ect = ECF1TeacherHistory::ECT.from_hash(hash.fetch(:ect)) if hash.key?(:ect)
    mentor = ECF1TeacherHistory::Mentor.from_hash(hash.fetch(:mentor)) if hash.key?(:mentor)

    participant_identity_updated_ats = []

    new(user:, ect:, mentor:, participant_identity_updated_ats:)
  end
end
