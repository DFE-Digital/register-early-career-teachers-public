module Schools
  class MentorsController < SchoolsController
    layout "full"

    def index
      @pagy, @mentors = pagy(Schools::Home.new(school:).mentors_with_ects, limit: 20)
    end

    def show
      @mentor = MentorAtSchoolPeriod.find(params[:id])
      @teacher = @mentor.teacher
      @ects = Schools::Home.new(school:).ects_with_mentors
    end
  end
end
