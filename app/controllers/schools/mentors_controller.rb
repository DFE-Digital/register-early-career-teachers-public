module Schools
  class MentorsController < SchoolsController
    layout "full"

    before_action :set_school_home
    before_action :set_mentor, only: :show
    before_action :set_teacher, only: :show
    before_action :set_ects, only: :show

    def index
      query = params[:q].presence
      mentors = Teachers::Search.new(mentor_at_school: school, query_string: query)
      results = mentors.search

      @pagy, @filtered_mentors = pagy_array(results, limit: 20)
      @has_any_mentors = query ? Teachers::Search.new(mentor_at_school: school).scope.exists? : results.any?
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
