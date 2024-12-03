module Migration
  class ParticipantProfileComponent < ViewComponent::Base
    attr_reader :participant_profile

    def initialize(participant_profile:)
      @participant_profile = Migration::ParticipantProfilePresenter.new(participant_profile)
    end

    def school_cohort_year
      participant_profile.school_cohort.cohort.start_year
    end

    def school_name_and_urn
      Schools::Name.new(school).name_and_urn
    end

    def school
      @school ||= participant_profile.school_cohort.school
    end

    def ect?
      participant_profile.ect?
    end

    def attributes_for(_attr)
      {}
    end
  end
end
