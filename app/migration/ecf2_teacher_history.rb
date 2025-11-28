class ECF2TeacherHistory
  class InvalidPeriodType < StandardError; end

  SchoolData = Data.define(:urn, :name)
  AppropriateBodyData = Data.define(:id, :name)
  MentorData = Data.define(:trn, :urn, :started_on, :finished_on)

  TeacherRow = Struct.new(
    :trn,
    :trnless,
    :trs_first_name,
    :trs_last_name,
    :corrected_name,

    :api_id,
    :api_ect_training_record_id,
    :api_mentor_training_record_id,
    :api_updated_at,

    :ect_pupil_premium_uplift,
    :ect_sparsity_uplift,
    :ect_first_became_eligible_for_training_at,
    :ect_payments_frozen_year,

    :mentor_became_ineligible_for_funding_on,
    :mentor_became_ineligible_for_funding_reason,
    :mentor_first_became_eligible_for_training_at,
    :mentor_payments_frozen_year
  ) do
    def to_hash
      override_trnless = trnless || false

      {
        trn:,
        trs_first_name:,
        trs_last_name:,
        trnless: override_trnless,
        corrected_name:,

        api_id:,
        api_ect_training_record_id:,
        api_mentor_training_record_id:,

        ect_pupil_premium_uplift:,
        ect_sparsity_uplift:,
        ect_first_became_eligible_for_training_at:,
        ect_payments_frozen_year:,

        mentor_became_ineligible_for_funding_on:,
        mentor_became_ineligible_for_funding_reason:,
        mentor_first_became_eligible_for_training_at:,
        mentor_payments_frozen_year:
      }.compact
    end
  end

  ECTAtSchoolPeriodRow = Struct.new(
    :started_on,
    :finished_on,
    :school,
    :email,
    :appropriate_body,
    :mentorship_period_rows,
    :training_period_rows
  ) do
    def to_hash
      {
        started_on:,
        finished_on:,
        school: real_school,
        email:,
        school_reported_appropriate_body: real_appropriate_body,
      }
    end

    def real_school
      GIAS::School.find_by!(urn: school.urn).school
    end

    def real_appropriate_body
      AppropriateBody.find(appropriate_body.id)
    end
  end

  MentorAtSchoolPeriodRow = Struct.new(
    :started_on,
    :finished_on,
    :school,
    :email,
    :training_period_rows
  ) do
    def to_hash
      {
        started_on:,
        finished_on:,
        school: real_school,
        email:
      }
    end

    def real_school
      GIAS::School.find_by!(urn: school.urn).school
    end
  end

  TrainingPeriodRow = Struct.new(
    :started_on,
    :finished_on,
    :training_programme,
    :lead_provider,
    :delivery_partner,
    :contract_period,
    :schedule,
    :deferred_at,
    :deferral_reason,
    :withdrawn_at,
    :withdrawal_reason
  ) do
    def to_hash
      {
        started_on:,
        finished_on:,
        training_programme:,
        schedule:,
        # FIXME: soon TPs can be both deferred and withdrawn, so this can be uncommented
        # deferred_at:,
        # deferral_reason:,
        # withdrawn_at:,
        # withdrawal_reason:
      }
    end

    def school_partnership(school:)
      SchoolPartnerships::Search.new(school:, contract_period:, lead_provider:, delivery_partner:)
        .school_partnerships
        .first
        .then { |school_partnership| { school_partnership: } }
    end
  end

  MentorshipPeriodRow = Struct.new(
    :started_on,
    :finished_on,
    :ecf_start_induction_record_id,
    :ecf_end_induction_record_id,
    :mentor_data
  ) do
    def to_hash
      { started_on:, finished_on:, ecf_start_induction_record_id:, ecf_end_induction_record_id: }
    end

    def mentor_at_school_period
      {
        # FIXME: use dates too to ensure we pick the right mentorship period, it's feasible
        #        that one teacher has multiple at the same school
        mentor: MentorAtSchoolPeriod
          .joins(:school, :teacher)
          .find_by(school: { urn: mentor_data.urn }, teacher: { trn: mentor_data.trn })
      }
    end
  end

  attr_reader :teacher_row,
              :ect_at_school_period_rows,
              :mentor_at_school_period_rows,
              :training_period_rows,
              :mentorship_period_rows

  def initialize(teacher_row:, ect_at_school_period_rows: [], mentor_at_school_period_rows: [])
    @teacher_row = teacher_row

    @ect_at_school_period_rows = ect_at_school_period_rows
    @mentor_at_school_period_rows = mentor_at_school_period_rows
  end

  def save_all_ect_data!
    Teacher.create!(**teacher_row).tap do |teacher|
      ect_at_school_period_rows.each do |ect_at_school_period_row|
        ECTAtSchoolPeriod.create!(teacher:, **ect_at_school_period_row).tap do |ect_at_school_period|
          ect_at_school_period_row.training_period_rows.each do |training_period_row|
            TrainingPeriod.create!(
              ect_at_school_period:,
              **training_period_row.school_partnership(school: ect_at_school_period_row.real_school),
              **training_period_row
            )
          end

          ect_at_school_period_row.mentorship_period_rows.each do |mentorship_period_row|
            MentorshipPeriod.create!(
              mentee: ect_at_school_period,
              **mentorship_period_row.mentor_at_school_period,
              **mentorship_period_row
            )
          end
        end
      end
    end
  end

  def save_all_mentor_data!
    Teacher.create!(**teacher_row).tap do |teacher|
      mentor_at_school_period_rows.each do |mentor_at_school_period_row|
        MentorAtSchoolPeriod.create!(teacher:, **mentor_at_school_period_row).tap do |mentor_at_school_period|
          mentor_at_school_period_row.training_period_rows.each do |training_period_row|
            TrainingPeriod.create!(
              mentor_at_school_period:,
              **training_period_row.school_partnership(school: mentor_at_school_period_row.real_school),
              **training_period_row
            )
          end
        end
      end
    end
  end
end
