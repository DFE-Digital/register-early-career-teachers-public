class ECF1TeacherHistory
  using Migration::CompactWithIgnore

  class InvalidPeriodType < StandardError; end

  User = Struct.new(:trn, :full_name, :user_id, :created_at, :updated_at, keyword_init: true) do
    def self.from_hash(hash)
      new(FactoryBot.attributes_for(:ecf1_teacher_history_user, **hash))
    end
  end

  ECT = Struct.new(:participant_profile_id,
                   :migration_mode,
                   :created_at,
                   :updated_at,
                   :induction_start_date,
                   :induction_completion_date,
                   :pupil_premium_uplift,
                   :sparsity_uplift,
                   :payments_frozen_cohort_start_year,
                   :states,
                   :induction_records,
                   keyword_init: true) do
                     def self.from_hash(hash)
                       hash.compact_with_ignore!

                       hash[:induction_records] = hash[:induction_records].map { InductionRecordRow.from_hash(it) }

                       new(FactoryBot.attributes_for(:ecf1_teacher_history_ect, **hash))
                     end
                   end


  Mentor = Struct.new(:participant_profile_id,
                      :migration_mode,
                      :created_at,
                      :updated_at,
                      :mentor_completion_date,
                      :mentor_completion_reason,
                      :payments_frozen_cohort_start_year,
                      :states,
                      :induction_records,
                      keyword_init: true) do
                        def self.from_hash(hash)
                          hash.compact_with_ignore!

                          hash[:induction_records] = hash[:induction_records].map { InductionRecordRow.from_hash(it) }

                          new(FactoryBot.attributes_for(:ecf1_teacher_history_mentor, **hash))
                        end
                      end


  ProfileStateRow = Struct.new(:state, :reason, :created_at)

  InductionRecordRow = Struct.new(:induction_record_id,
                                  :start_date,
                                  :end_date,
                                  :created_at,
                                  :updated_at,
                                  :cohort_year,
                                  :school_urn,
                                  :schedule_info,
                                  :preferred_identity_email,
                                  :mentor_profile_id,
                                  :training_status,
                                  :induction_status,
                                  :training_programme,
                                  :training_provider_info,
                                  :appropriate_body,
                                  keyword_init: true) do
                                    def self.from_hash(hash)
                                      hash.compact_with_ignore!

                                      new(FactoryBot.attributes_for(:ecf1_teacher_history_induction_record_row, **hash))
                                    end
                                  end


  TrainingProviderInfo = Struct.new(
    :lead_provider_info,
    :delivery_partner_info,
    :cohort_year
  )

  attr_accessor :user, :ect, :mentor, :participant_identity_updated_ats

  def initialize(user:, ect: nil, mentor: nil, participant_identity_updated_ats: [])
    @user = user
    @ect = ect
    @mentor = mentor
    @participant_identity_updated_ats = participant_identity_updated_ats
  end

  def self.build(teacher_profile:)
    user_record = teacher_profile.user
    ect_profile = teacher_profile.participant_profiles.ect.first
    mentor_profile = teacher_profile.participant_profiles.mentor.first

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

  # TODO: on Monday
  #   - add a full example hash here showing all the available keys
  #   - do we need the array of participant_identity_updated_ats? don't we just want the
  #     latest?
  #   - add a spec for someone who's been an ECT and a mentor
  #   - deal with lead providers, delivery partners, schools and appropriate bodies in comparison
  def self.from_hash(hash)
    hash.compact_with_ignore!

    user = ECF1TeacherHistory::User.from_hash(hash.slice(:trn, :full_name).compact)

    ect = if hash.key?(:ect)
            ECF1TeacherHistory::ECT.from_hash(hash.fetch(:ect).slice(:participant_profile_id, :induction_records))
          end

    mentor = if hash.key?(:mentor)
               ECF1TeacherHistory::Mentor.from_hash(hash.fetch(:mentor).slice(:participant_profile_id, :induction_records))
             end

    participant_identity_updated_ats = []

    new(user:, ect:, mentor:, participant_identity_updated_ats:)
  end

  def self.build_appropriate_body(induction_record:)
    appropriate_body = induction_record.appropriate_body
    return if appropriate_body.blank?

    Types::AppropriateBodyData.new(ecf1_id: appropriate_body.id, name: appropriate_body.name)
  end

  def self.build_ect_data(participant_profile:)
    migration_mode = migration_mode(participant_profile:)

    ECT.new(
      participant_profile_id: participant_profile.id,
      migration_mode:,
      created_at: participant_profile.created_at,
      updated_at: participant_profile.updated_at,
      induction_start_date: participant_profile.induction_start_date,
      induction_completion_date: participant_profile.induction_completion_date,
      pupil_premium_uplift: participant_profile.pupil_premium_uplift,
      sparsity_uplift: participant_profile.sparsity_uplift,
      payments_frozen_cohort_start_year: participant_profile.previous_payments_frozen_cohort_start_year,
      states: build_profile_states(participant_profile:),
      induction_records: build_induction_record_rows(participant_profile:, migration_mode:)
    )
  end

  # Build rows for all the induction records of the participant
  def self.build_induction_record_rows(participant_profile:, migration_mode:)
    row_matches = ->(rows, row) do
      rows.any? do |r|
        [r.training_provider_info&.lead_provider_info&.ecf1_id, r.school_urn, r.cohort_year] ==
          [row.training_provider_info&.lead_provider_info&.ecf1_id, row.school_urn, row.cohort_year]
      end
    end

    rows = participant_profile.induction_records.order(:start_date, :created_at).map do |induction_record|
      build_induction_record_row(induction_record:)
    end

    if migration_mode == "latest_induction_records"
      rows.reverse.each_with_object([]) do |row, result|
        result.unshift(row) unless row_matches.call(result, row)
      end
    else
      rows
    end
  end

  def self.build_induction_record_row(induction_record:)
    InductionRecordRow.new(
      induction_record_id: induction_record.id,
      start_date: induction_record.start_date,
      end_date: induction_record.end_date,
      created_at: induction_record.created_at,
      updated_at: induction_record.updated_at,
      cohort_year: induction_record.schedule.cohort.start_year,
      school_urn: induction_record.induction_programme.school_cohort.school.urn,
      schedule_info: build_schedule_info(schedule: induction_record.schedule),
      preferred_identity_email: induction_record.preferred_identity.email,
      mentor_profile_id: induction_record.mentor_profile_id,
      training_status: induction_record.training_status,
      induction_status: induction_record.induction_status,
      training_programme: induction_record.induction_programme.training_programme,
      training_provider_info: build_training_provider_info(induction_record:),
      appropriate_body: build_appropriate_body(induction_record:)
    )
  end

  def self.build_mentor_data(participant_profile:)
    migration_mode = migration_mode(participant_profile:)

    Mentor.new(
      participant_profile_id: participant_profile.id,
      migration_mode:,
      created_at: participant_profile.created_at,
      updated_at: participant_profile.updated_at,
      mentor_completion_date: participant_profile.mentor_completion_date,
      mentor_completion_reason: participant_profile.mentor_completion_reason,
      payments_frozen_cohort_start_year: participant_profile.previous_payments_frozen_cohort_start_year,
      states: build_profile_states(participant_profile:),
      induction_records: build_induction_record_rows(participant_profile:, migration_mode:)
    )
  end

  def self.build_profile_states(participant_profile:)
    participant_profile.participant_profile_states.order(:created_at).map do |profile_state|
      ProfileStateRow.new(state: profile_state.state, reason: profile_state.reason, created_at: profile_state.created_at)
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

  def self.migration_mode(participant_profile:)
    return "latest_induction_records" if participant_profile.more_than_two_induction_records?
    return "latest_induction_records" if participant_profile.two_induction_records_that_overlap?

    "all_induction_records"
  end
end
