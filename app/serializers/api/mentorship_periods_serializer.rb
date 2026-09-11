class API::MentorshipPeriodsSerializer < Blueprinter::Base
  def self.dependencies
    [
      {
        mentee: %i[teacher school],
        mentor: [
          :teacher,
          { training_periods: :lead_provider }
        ]
      }
    ]
  end

  class AttributesSerializer < Blueprinter::Base
    field(:started_on)
    field(:finished_on)
    field(:updated_at)

    field(:school_urn) do |mentorship_period|
      mentorship_period.mentee.school.urn
    end

    field(:ect_participant_id) do |mentorship_period|
      mentorship_period.mentee.teacher.api_ect_training_record_id
    end

    field(:mentor_participant_id) do |mentorship_period|
      mentorship_period.mentor.teacher.api_mentor_training_record_id
    end

    field(:mentor_email) do |mentorship_period|
      mentorship_period.mentor.email
    end

    field(:mentor_full_name) { |mentorship_period| Teachers::Name.new(mentorship_period.mentor.teacher).full_name }

    field(:mentorship_status) do |mentorship_period, options|
      API::MentorshipPeriods::MentorshipStatus.new(
        mentorship_period:,
        lead_provider_id: options[:lead_provider_id]
      ).status
    end
  end

  identifier :api_id, name: :id
  field(:type) { "mentorship-periods" }

  association :attributes, blueprint: AttributesSerializer do |mentorship_period|
    mentorship_period
  end
end
