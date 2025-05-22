module Schools
  class MentorsController < SchoolsController
    layout "full"

    before_action :set_school_home
    before_action :set_mentor, only: :show
    before_action :set_teacher, only: :show
    before_action :set_ects, only: :show

    def index
      @pagy, @mentors = pagy_array(Teachers::Search.new(mentor_at_school: school, query_string: params[:q]).search, limit: 20)
    end

    def show
    end

  private

    def set_school_home
      @school_home = Schools::Home.new(school:)
    end

    def set_mentor
      @mentor = MentorAtSchoolPeriod.find(params[:id])
    end

    def set_teacher
      @teacher = @mentor.teacher
    end

    def set_ects
      @ects = @school_home.ects_with_mentors
    end
  end
end
