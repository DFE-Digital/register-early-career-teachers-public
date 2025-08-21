module Schools
  class Home
    attr_accessor :school

    def initialize(school:)
      @school = school
    end

    def ects_with_mentors
      ECTAtSchoolPeriod
        .visible_for_school(school)
        .eager_load(:teacher, :school, mentors: :teacher)
        .joins(:mentorship_periods)
        .merge(MentorshipPeriod.ongoing_today.or(MentorshipPeriod.starting_tomorrow_or_after))
        .distinct
        .order(:started_on)
    end

    def mentors_with_ects
      MentorAtSchoolPeriod
        .where(school:)
        .ongoing_today_or_starting_tomorrow_or_after
        .eager_load(:teacher, :school)
    end
  end
end
