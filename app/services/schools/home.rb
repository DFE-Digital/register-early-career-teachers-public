module Schools
  class Home
    attr_accessor :school

    def initialize(school:)
      @school = school
    end

    def ects_with_mentors
      ECTAtSchoolPeriod
        .where(school:)
        .eager_load(:teacher, :school, mentors: :teacher)
        .merge(MentorshipPeriod.ongoing)
    end
  end
end
