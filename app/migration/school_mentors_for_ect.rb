class SchoolMentorsForECT
  def initialize(induction_records:)
    @induction_records = induction_records
  end

  def mentor_at_school_periods
    find_mentor_at_school_periods_for_ect
  end

private

  attr_reader :induction_records

  def find_mentor_at_school_periods_for_ect
    schools = induction_records.map(&:school).uniq
    mentor_profile_ids = induction_records.map(&:mentor_profile_id).compact.uniq

    mentor_at_school_periods = ::MentorAtSchoolPeriod.joins(:school, :teacher)
      .where(schools: { urn: schools.map(&:urn) },
             teachers: { api_mentor_training_record_id: mentor_profile_ids })

    mentor_at_school_periods.map do |mentor_at_school_period|
      build_mentor_at_school_period(mentor_at_school_period:, schools:)
    end
  end

  def build_mentor_at_school_period(mentor_at_school_period:, schools:)
    ECF1TeacherHistory::MentorAtSchoolPeriod.new(
      mentor_at_school_period_id: mentor_at_school_period.id,
      started_on: mentor_at_school_period.started_on,
      finished_on: mentor_at_school_period.finished_on,
      created_at: mentor_at_school_period.created_at,
      updated_at: mentor_at_school_period.updated_at,
      school: schools.find { |s| s.urn == mentor_at_school_period.school.urn.to_s },
      teacher: build_teacher_data(mentor_at_school_period.teacher)
    )
  end

  def build_teacher_data(teacher)
    Types::TeacherData.new(trn: teacher.trn, api_mentor_training_record_id: teacher.api_mentor_training_record_id)
  end
end
