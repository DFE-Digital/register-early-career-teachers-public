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

    field(:school_urn) { "123456" }

    field(:ect_participant_id) { SecureRandom.uuid }

    field(:mentor_participant_id) { SecureRandom.uuid }

    field(:mentor_email) { Faker::Internet.email }

    field(:mentor_full_name) { Faker::Name.name }

    field(:mentorship_status) do |mentorship_period, options|
      mentorship_status(mentorship_period, options).first
    end

    field(:mentorship_status_reason) do |mentorship_period, options|
      mentorship_status(mentorship_period, options).last
    end

    def self.mentorship_status(mentorship_period, options)
      options[:mentorship_statuses] ||= {}

      options[:mentorship_statuses][mentorship_period.id] ||= API::MentorshipPeriods::MentorshipStatus.new(
        mentorship_period:,
        lead_provider_id: options[:lead_provider_id]
      ).status
    end
  end

  identifier :uuid do |_object|
    SecureRandom.uuid
  end
  field(:type) { "mentorship-periods" }

  association :attributes, blueprint: AttributesSerializer do |mentorship_period|
    mentorship_period
  end
end
