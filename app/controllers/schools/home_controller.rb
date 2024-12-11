module Schools
  class HomeController < SchoolsController
    layout "full"

    def index
      teacher_service = Schools::Teacher.new(school.urn)
      @relationships = teacher_service.fetch_etcs_and_mentors
    end
  end
end
