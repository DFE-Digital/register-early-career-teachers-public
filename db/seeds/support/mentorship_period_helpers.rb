module MentorshipPeriodHelpers
  def create_mentorship_period_for(
    mentee_school_partnership:,
    mentor_school_partnership: mentee_school_partnership,
    mentee: FactoryBot.create(:teacher, :with_realistic_name),
    mentor: FactoryBot.create(:teacher, :with_realistic_name),
    create_mentor_training_period: true,
    refresh_metadata: false
  )
    # Mentorship periods must be within the same school
    # (mirrors MentorshipPeriod model validation)
    if mentor_school_partnership.school_id != mentee_school_partnership.school_id
      raise "Refusing to create cross-school mentorship: " \
            "#{mentor_school_partnership.school_id} vs #{mentee_school_partnership.school_id}"
    end

    school = mentee_school_partnership.school

    mentee_school_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher: mentee,
      school:,
      started_on: 2.months.ago
    )

    FactoryBot.create(
      :training_period,
      :for_ect,
      :ongoing,
      started_on: 1.month.ago,
      ect_at_school_period: mentee_school_period,
      school_partnership: mentee_school_partnership
    )

    mentor_school_period = FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher: mentor,
      school:,
      started_on: 2.months.ago
    )

    if create_mentor_training_period
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :ongoing,
        started_on: 1.month.ago,
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

    # Required for specs that query via metadata tables rather than live joins
    if refresh_metadata
      Metadata::Handlers::Teacher.new(mentor).refresh_metadata!
      Metadata::Handlers::Teacher.new(mentee).refresh_metadata!
    end

    mentorship_period
  end
end
