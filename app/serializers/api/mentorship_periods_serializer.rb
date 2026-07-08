class API::MentorshipPeriodsSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    field(:started_on)
    field(:finished_on)

    field(:school_urn) do |mentorship_period|
      mentorship_period.mentee.school.urn
    end

    field(:ect_participant_id) do |mentorship_period|
      mentorship_period.mentee.teacher.api_ect_training_record_id
    end

    field(:mentor_participant_id) do |mentorship_period|
      mentorship_period.mentor.teacher.api_ect_training_record_id
    end

    field(:mentor_email) do |mentorship_period|
      mentorship_period.mentor.email
    end

    field(:mentor_full_name) { |mentorship_period| Teachers::Name.new(mentorship_period.mentor.teacher).full_name }

    field(:mentor_training_status) do |mentorship_period, options|
      actively_training = mentorship_period.mentor.training_periods.any? { it.lead_provider&.id == options[:lead_provider_id] }

      if actively_training
        :actively_training
      else
        :not_actively_training
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "mentorship-periods" }

  association :attributes, blueprint: AttributesSerializer do |mentorship_period|
    mentorship_period
  end
end
