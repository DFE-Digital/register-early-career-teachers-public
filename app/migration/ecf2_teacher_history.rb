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
          training_period = nil
          mentor_at_school_period_row.training_period_rows.each do |training_period_row|
            training_period = TrainingPeriod.create!(
              mentor_at_school_period:,
              **training_period_row.school_partnership(school: mentor_at_school_period_row.real_school),
              **training_period_row
            )
          end

          record_import_event(
            teacher:,
            mentor_at_school_period:,
            training_period:,
            import_note: mentor_at_school_period_row.import_note
          )
        end
      end
    end
  end

private

  def record_import_event(teacher:, mentor_at_school_period: nil, ect_at_school_period: nil, training_period: nil, import_note: nil)
    return if import_note.blank?

    Events::Record.record_imported_from_ecf1_event!(
      author: Events::SystemAuthor.new,
      teacher:,
      body: import_note,
      mentor_at_school_period:,
      ect_at_school_period:,
      training_period:,
      school: mentor_at_school_period&.school || ect_at_school_period&.school,
      happened_at: Time.zone.now
    )
  end
end
