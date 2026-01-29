ECF1TeacherHistory::MentorAtSchoolPeriod = Struct.new(
  :mentor_at_school_period_id,
  :started_on,
  :finished_on,
  :created_at,
  :updated_at,
  :school,
  :teacher,
  keyword_init: true
) do
  using Migration::CompactWithIgnore

  def self.from_hash(hash)
    hash.compact_with_ignore!

    if (school = hash[:school])
      hash[:school] = Types::SchoolData.new(**school)
    end

    if (teacher = hash[:teacher])
      hash[:teacher] = Types::TeacherData.new(**teacher)
    end

    new(FactoryBot.attributes_for(:ecf1_teacher_history_mentor_at_school_period_row, **hash))
  end

  def range
    started_on..finished_on
  end

  def range_covers_finish_but_not_start?(start, finish)
    range.cover?(finish) && !range.cover?(start)
  end

  def ongoing?
    end_date.nil?
  end
end
