module MentorshipPeriodHelpers
  def create_mentorship_period_for(
    mentee_school_partnership:,
    mentor_school_partnership: mentee_school_partnership,
    mentee: FactoryBot.create(:teacher, :with_realistic_name),
    mentor: FactoryBot.create(:teacher, :with_realistic_name),
    create_mentor_training_period: true,
    refresh_metadata: false
  )
    assert_same_school!(mentee_school_partnership, mentor_school_partnership)

    school = mentee_school_partnership.school
    school_started_on = 2.months.ago
    training_started_on = 1.month.ago

    mentee_school_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher: mentee,
      school:,
      started_on: school_started_on
    )

    FactoryBot.create(
      :training_period,
      :for_ect,
      :ongoing,
      started_on: training_started_on,
      ect_at_school_period: mentee_school_period,
      school_partnership: mentee_school_partnership
    )

    mentor_school_period = FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher: mentor,
      school:,
      started_on: school_started_on
    )

    if create_mentor_training_period
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :ongoing,
        started_on: training_started_on,
        mentor_at_school_period: mentor_school_period,
        school_partnership: mentor_school_partnership
      )
    end

    mentorship_period = FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: mentee_school_period,
      mentor: mentor_school_period
    )

    refresh_teacher_metadata!(mentor, mentee) if refresh_metadata

    mentorship_period
  end

private

  def assert_same_school!(mentee_school_partnership, mentor_school_partnership)
    return if mentor_school_partnership.school_id == mentee_school_partnership.school_id

    raise "Refusing to create cross-school mentorship: " \
          "#{mentor_school_partnership.school_id} vs #{mentee_school_partnership.school_id}"
  end

  def refresh_teacher_metadata!(*teachers)
    teachers.each { |t| Metadata::Handlers::Teacher.new(t).refresh_metadata! }
  end
end
