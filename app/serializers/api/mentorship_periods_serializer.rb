class API::MentorshipPeriodsSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    field(:started_on)
    field(:finished_on)

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
  end

  identifier :api_id, name: :id
  field(:type) { "mentorship-periods" }

  association :attributes, blueprint: AttributesSerializer do |mentorship_period|
    mentorship_period
  end
end
