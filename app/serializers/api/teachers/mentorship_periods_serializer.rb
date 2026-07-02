class API::Teachers::MentorshipPeriodsSerializer < Blueprinter::Base
  class MentorshipPeriodSerializer < Blueprinter::Base
    field(:started_on)
    field(:finished_on)

    field(:mentor_email) do |mentorship_period|
      mentorship_period.mentor.email
    end

    field(:mentor_full_name) { |mentorship_period| Teachers::Name.new(mentorship_period.mentor.teacher).full_name }
  end

  class AttributesSerializer < Blueprinter::Base
    field(:training_record_id) do |data|
      data[:teacher].api_ect_training_record_id
    end

    field(:school_urn) do |data|
      data[:latest_ect_training_period].ect_at_school_period.school.urn
    end

    association :mentorship_periods, blueprint: MentorshipPeriodSerializer do |data|
      data[:mentorship_periods]
    end
  end

  identifier :api_id, name: :id
  field(:type) { "mentorship-periods" }

  association :attributes, blueprint: AttributesSerializer do |teacher, options|
    latest_ect_training_period = lead_provider_metadata(teacher:, options:).latest_ect_training_period
    mentorship_periods = latest_ect_training_period.ect_at_school_period.mentorship_periods

    { teacher:, latest_ect_training_period:, mentorship_periods: }
  end

  class << self
    def lead_provider_metadata(teacher:, options:)
      teacher.lead_provider_metadata.select { it.lead_provider_id == options[:lead_provider_id] }.sole
    end
  end
end
