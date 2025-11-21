module MentorshipPeriodHelpers
  def create_mentorship_period_for(mentee_school_partnership:, mentor_school_partnership: FactoryBot.create(:school_partnership))
    mentee = FactoryBot.create(:teacher, :with_realistic_name)
    mentee_school_period = FactoryBot.create(:ect_at_school_period, :ongoing, teacher: mentee, started_on: 2.months.ago, school: mentee_school_partnership.school)
    FactoryBot.create(:training_period, :for_ect, started_on: 1.month.ago, ect_at_school_period: mentee_school_period, school_partnership: mentee_school_partnership)

    unfunded_mentor = FactoryBot.create(:teacher, :with_realistic_name)
    unfunded_mentor_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: unfunded_mentor, started_on: 2.months.ago, school: mentor_school_partnership.school)
    FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period: unfunded_mentor_school_period, school_partnership: mentor_school_partnership)

    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: mentee_school_period,
      mentor: unfunded_mentor_school_period
    )
  end
end
