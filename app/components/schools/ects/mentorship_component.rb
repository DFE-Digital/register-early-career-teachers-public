module Schools::ECTs
  class MentorshipComponent < ApplicationComponent
    include ECTHelper

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

  private

    def assign_or_create_mentor_link
      govuk_link_to(
        "Assign a mentor for this ECT",
        assign_or_create_mentor_path(ect_at_school_period),
        no_visited_state: true
      )
    end

    attr_reader :ect_at_school_period

    def mentorship
      @mentorship ||= ECTAtSchoolPeriods::Mentorship.new(ect_at_school_period)
    end

    def upcoming_mentorships
      mentorship.upcoming_mentorship_periods.reject do
        it == mentorship.current_or_next_mentorship_period
      end
    end

    def upcoming_mentorship_descriptions
      upcoming_mentorships.map { upcoming_mentorship_description(it) }
    end

    def upcoming_mentorship_description(mentorship_period)
      mentor_name = Teachers::Name.new(mentorship_period.mentor.teacher).full_name
      "#{mentor_name} (from #{mentorship_period.started_on.to_fs(:govuk)})"
    end
  end
end
