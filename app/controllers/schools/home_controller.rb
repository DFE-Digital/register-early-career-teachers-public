module Schools
  class HomeController < SchoolsController
    layout "full"

    def index
      @ects = ects_and_mentors
    end

  private

    def ects_and_mentors
      ECTAtSchoolPeriod
        .where(school:)
        .eager_load(:teacher, :school, mentors: :teacher)
        .merge(MentorshipPeriod.ongoing)
    end
  end
end
