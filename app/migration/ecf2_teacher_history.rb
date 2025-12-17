class ECF2TeacherHistory
  class InvalidPeriodType < StandardError; end

  MIGRATION_ITEM_TYPE = "Migration::InductionRecord"

  SchoolData = Data.define(:urn, :name)
  AppropriateBodyData = Data.define(:id, :name)
  MentorData = Data.define(:trn, :urn, :started_on, :finished_on)

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
    teacher = find_or_create_teacher!
    save_ect_periods!(teacher)
    teacher
  end

  def save_all_mentor_data!
    teacher = find_or_create_teacher!
    save_mentor_periods!(teacher)
    teacher
  end

  def success?
    !@failed
  end

private

  def find_or_create_teacher!
    teacher = if teacher_row.trn.present?
                Teacher.find_or_initialize_by(trn: teacher_row.trn)
              else
                Teacher.find_or_initialize_by(api_id: teacher_row.api_id)
              end

    teacher.assign_attributes(**teacher_row.to_hash)
    teacher.save!
    teacher
  end

  def with_failure_recording(teacher:, model:, migration_item_id:)
    yield
  rescue ActiveRecord::ActiveRecordError => e
    record_failure!(teacher:, model:, message: e.message, migration_item_id:)
  end

  def record_failure!(teacher:, model:, message:, migration_item_id:)
    @failed = true
    TeacherMigrationFailure.create!(
      teacher:,
      model:,
      message:,
      migration_item_id:,
      migration_item_type: MIGRATION_ITEM_TYPE
    )
  end

  def school_partnership_for(training_period_row, school:)
    return { school_partnership: nil } unless training_period_row.training_programme.to_s == "provider_led"

    training_period_row.school_partnership(school:)
  end

  def save_ect_periods!(teacher)
    ect_at_school_period_rows.each do |ect_at_school_period_row|
      with_failure_recording(teacher:, model: :ect_at_school_period, migration_item_id: ect_at_school_period_row.training_period_rows.first&.ecf_start_induction_record_id) do
        ect_at_school_period = ECTAtSchoolPeriod.create!(teacher:, **ect_at_school_period_row)

        ect_at_school_period_row.training_period_rows.each do |training_period_row|
          with_failure_recording(teacher:, model: :training_period, migration_item_id: training_period_row.ecf_start_induction_record_id) do
            TrainingPeriod.create!(
              ect_at_school_period:,
              **school_partnership_for(training_period_row, school: ect_at_school_period_row.real_school),
              **training_period_row
            )
          end
        end

        ect_at_school_period_row.mentorship_period_rows.each do |mentorship_period_row|
          with_failure_recording(teacher:, model: :mentorship_period, migration_item_id: mentorship_period_row.ecf_start_induction_record_id) do
            if mentorship_period_row.mentor_teacher.nil?
              raise ActiveRecord::RecordNotFound, "Mentor not found in migrated data"
            end

            mentor_period = mentorship_period_row.mentor_at_school_period[:mentor]

            if mentor_period.nil?
              raise ActiveRecord::RecordNotFound, "No MentorAtSchoolPeriod found for mentorship dates"
            end

            MentorshipPeriod.create!(
              mentee: ect_at_school_period,
              mentor: mentor_period,
              **mentorship_period_row
            )
          end
        end
      end
    end
  end

  def save_mentor_periods!(teacher)
    mentor_at_school_period_rows.each do |mentor_at_school_period_row|
      with_failure_recording(teacher:, model: :mentor_at_school_period, migration_item_id: mentor_at_school_period_row.training_period_rows.first&.ecf_start_induction_record_id) do
        mentor_at_school_period = MentorAtSchoolPeriod.create!(teacher:, **mentor_at_school_period_row)

        mentor_at_school_period_row.training_period_rows.each do |training_period_row|
          with_failure_recording(teacher:, model: :training_period, migration_item_id: training_period_row.ecf_start_induction_record_id) do
            TrainingPeriod.create!(
              mentor_at_school_period:,
              **school_partnership_for(training_period_row, school: mentor_at_school_period_row.real_school),
              **training_period_row
            )
          end
        end
      end
    end
  end
end
