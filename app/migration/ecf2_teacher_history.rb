class ECF2TeacherHistory
  class InvalidPeriodType < StandardError; end

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

  def save_all!
    teacher = find_or_create_teacher!
    save_ect_periods!(teacher)
    save_mentor_periods!(teacher)
    teacher
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

  def save_ect_periods!(teacher)
    ect_at_school_period_rows.each do |ect_at_school_period_row|
      ect_at_school_period = ECTAtSchoolPeriod.create!(teacher:, **ect_at_school_period_row)

      ect_at_school_period_row.training_period_rows.each do |training_period_row|
        TrainingPeriod.create!(
          ect_at_school_period:,
          **training_period_row.school_partnership(school: ect_at_school_period_row.real_school),
          **training_period_row
        )
      rescue ActiveRecord::ActiveRecordError => e
        TeacherMigrationFailure.create!(
          teacher:,
          model: :training_period,
          message: e.message,
          migration_item_id: training_period_row.ecf_start_induction_record_id,
          migration_item_type: "Migration::InductionRecord"
        )
      end

      ect_at_school_period_row.mentorship_period_rows.each do |mentorship_period_row|
        MentorshipPeriod.create!(
          mentee: ect_at_school_period,
          **mentorship_period_row.mentor_at_school_period,
          **mentorship_period_row
        )
      end
    rescue ActiveRecord::ActiveRecordError => e
      TeacherMigrationFailure.create!(
        teacher:,
        model: :ect_at_school_period,
        message: e.message,
        migration_item_id: ect_at_school_period_row.training_period_rows.first&.ecf_start_induction_record_id,
        migration_item_type: "Migration::InductionRecord"
      )
    end
  end

  def save_mentor_periods!(teacher)
    mentor_at_school_period_rows.each do |mentor_at_school_period_row|
      mentor_at_school_period = MentorAtSchoolPeriod.create!(teacher:, **mentor_at_school_period_row)

      mentor_at_school_period_row.training_period_rows.each do |training_period_row|
        TrainingPeriod.create!(
          mentor_at_school_period:,
          **training_period_row.school_partnership(school: mentor_at_school_period_row.real_school),
          **training_period_row
        )
      rescue ActiveRecord::ActiveRecordError => e
        TeacherMigrationFailure.create!(
          teacher:,
          model: :training_period,
          message: e.message,
          migration_item_id: training_period_row.ecf_start_induction_record_id,
          migration_item_type: "Migration::InductionRecord"
        )
      end
    rescue ActiveRecord::ActiveRecordError => e
      TeacherMigrationFailure.create!(
        teacher:,
        model: :mentor_at_school_period,
        message: e.message,
        migration_item_id: mentor_at_school_period_row.training_period_rows.first&.ecf_start_induction_record_id,
        migration_item_type: "Migration::InductionRecord"
      )
    end
  end
end
