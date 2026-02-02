class ECF2TeacherHistory
  class InvalidPeriodType < StandardError; end

  MIGRATION_ITEM_TYPE = "Migration::InductionRecord"

  AppropriateBodyData = Data.define(:id, :name)
  MentorData = Data.define(:trn, :urn, :started_on, :finished_on)

  attr_reader :teacher,
              :ect_at_school_periods,
              :mentor_at_school_periods,
              :ecf2_ect_combination_summaries,
              :ecf2_mentor_combination_summaries,
              :training_periods,
              :mentorship_periods

  def initialize(teacher:, ect_at_school_periods: [], mentor_at_school_periods: [])
    @teacher = teacher
    @ect_at_school_periods = ect_at_school_periods
    @mentor_at_school_periods = mentor_at_school_periods
    @ecf2_ect_combination_summaries = []
    @ecf2_mentor_combination_summaries = []
  end

  def save_all_ect_data!
    find_or_create_teacher!.tap do |teacher|
      save_ect_periods!(teacher)
      save_ect_combination_summaries!
    end
  end

  def save_all_mentor_data!
    find_or_create_teacher!.tap do |teacher|
      save_mentor_periods!(teacher)
      save_mentor_combination_summaries!
    end
  end

  def success?
    !@failed
  end

  def to_h
    {
      teacher: {
        trn: teacher.trn,
        api_ect_training_record_id: teacher.api_ect_training_record_id,
        ect_at_school_periods: ect_at_school_periods.map(&:to_h),
        mentor_at_school_periods: mentor_at_school_periods.map(&:to_h),
        ecf2_ect_combination_summaries:,
        ecf2_mentor_combination_summaries:
      }
    }
  end

  def ecf1_ect_combination_summaries
    @ecf1_ect_combination_summaries ||= ect_at_school_periods
                                          .flat_map(&:training_periods)
                                          .map(&:combination)
                                          .compact
                                          .map(&:summary)
  end

  def ecf1_mentor_combination_summaries
    @ecf1_mentor_combination_summaries ||= mentor_at_school_periods
                                             .flat_map(&:training_periods)
                                             .map(&:combination)
                                             .compact
                                             .map(&:summary)
  end

private

  def find_or_create_teacher!
    found_teacher = if teacher.trn.present?
                      ::Teacher.find_or_initialize_by(trn: teacher.trn)
                    else
                      ::Teacher.find_or_initialize_by(api_id: teacher.api_id)
                    end
    with_failure_recording(teacher: found_teacher, model: :teacher, migration_item_id: teacher.api_id) do
      found_teacher.assign_attributes(**teacher.to_hash)
      found_teacher.save!
      found_teacher
    end
  end

  def with_failure_recording(teacher:, model:, migration_item_id:)
    yield
  rescue ActiveRecord::ActiveRecordError => e
    record_failure!(teacher:, model:, message: e.message, migration_item_id:)
  end

  def record_failure!(teacher:, model:, message:, migration_item_id:)
    @failed = true

    record_failed_combinations(at_school_period: model, message:) if model.respond_to?(:training_periods)
    record_failed_combination(combination: model.combination, message:) if model.respond_to?(:combination)
    model_identifier = model.is_a?(Symbol) ? model : model.class.name.demodulize.underscore

    if teacher.id
      ::TeacherMigrationFailure.create!(
        teacher:,
        model: model_identifier,
        message:,
        migration_item_id:,
        migration_item_type: MIGRATION_ITEM_TYPE
      )
    end
  end

  def record_failed_combinations(at_school_period:, message:)
    at_school_period.training_periods.map(&:combination).each do |combination|
      record_failed_combination(combination:, message:)
    end
  end

  def record_failed_combination(combination:, message:)
    DataMigrationFailedCombination.create!(**combination.to_h, failure_message: message)
  end

  def school_partnership_for(training_period)
    return { school_partnership: nil } unless training_period.training_programme.to_s == "provider_led"

    training_period.school_partnership
  end

  def data_migration_teacher_combinations
    @data_migration_teacher_combinations ||= DataMigrationTeacherCombination.find_or_initialize_by(trn: teacher.trn)
  end

  def save_ect_combination_summaries!
    data_migration_teacher_combinations.update!(
      ecf1_ect_profile_id: teacher.api_ect_training_record_id,
      ecf1_ect_combinations: ecf1_ect_combination_summaries,
      ecf2_ect_combinations: ecf2_ect_combination_summaries
    )
  end

  def save_mentor_combination_summaries!
    data_migration_teacher_combinations.update!(
      ecf1_mentor_profile_id: teacher.api_mentor_training_record_id,
      ecf1_mentor_combinations: ecf1_mentor_combination_summaries,
      ecf2_mentor_combinations: ecf2_mentor_combination_summaries
    )
  end

  def save_ect_periods!(found_teacher)
    ect_at_school_periods.each do |ect_at_school_period|
      with_failure_recording(teacher: found_teacher,
                             model: ect_at_school_period,
                             migration_item_id: ect_at_school_period.training_periods.first&.ecf_start_induction_record_id) do
        created_ect_at_school_period = ::ECTAtSchoolPeriod.create!(teacher: found_teacher, **ect_at_school_period)

        ect_at_school_period.training_periods.each do |training_period|
          with_failure_recording(teacher: found_teacher,
                                 model: training_period,
                                 migration_item_id: training_period.ecf_start_induction_record_id) do
            ::TrainingPeriod.create!(
              ect_at_school_period: created_ect_at_school_period,
              **school_partnership_for(training_period),
              **training_period
            )
            ecf2_ect_combination_summaries << training_period.combination.summary
          end
        end

        ect_at_school_period.mentorship_periods.each do |mentorship_period|
          with_failure_recording(teacher: found_teacher, model: :mentorship_period, migration_item_id: mentorship_period.ecf_start_induction_record_id) do
            ::MentorshipPeriod.create!(mentee: created_ect_at_school_period, **mentorship_period)
          end
        end
      end
    end
  end

  def save_mentor_periods!(found_teacher)
    mentor_at_school_periods.each do |mentor_at_school_period|
      with_failure_recording(teacher: found_teacher,
                             model: mentor_at_school_period,
                             migration_item_id: mentor_at_school_period.training_periods.first&.ecf_start_induction_record_id) do
        created_mentor_at_school_period = ::MentorAtSchoolPeriod.create!(teacher: found_teacher, **mentor_at_school_period)

        mentor_at_school_period.training_periods.each do |training_period|
          with_failure_recording(teacher: found_teacher,
                                 model: training_period,
                                 migration_item_id: training_period.ecf_start_induction_record_id) do
            ::TrainingPeriod.create!(
              mentor_at_school_period: created_mentor_at_school_period,
              **school_partnership_for(training_period),
              **training_period
            )
            ecf2_mentor_combination_summaries << training_period.combination.summary
          end
        end
      end
    end
  end
end
