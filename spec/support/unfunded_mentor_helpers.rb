module UnfundedMentorHelpers
  include MentorshipPeriodHelpers

  def create_unfunded_mentor_for(school_partnership:)
    period = create_mentorship_period_for(
      mentee_school_partnership: school_partnership,
      create_mentor_training_period: false
    )

    mentor = period.mentor.teacher
    mentee = period.mentee.teacher

    mentor.update!(api_id: SecureRandom.uuid) if mentor.api_id.blank?
    mentee.update!(api_id: SecureRandom.uuid) if mentee.api_id.blank?

    mentee.update!(api_ect_training_record_id: SecureRandom.uuid) if mentee.api_ect_training_record_id.blank?
    mentor.update!(api_mentor_training_record_id: SecureRandom.uuid) if mentor.api_mentor_training_record_id.blank?

    Metadata::Handlers::Teacher.new(mentor).refresh_metadata!
    Metadata::Handlers::Teacher.new(mentee).refresh_metadata!

    mentor
  end
end
