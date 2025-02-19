module Schools
  class MentorsController < SchoolsController
    layout "full"

    def index
      @mentors = Schools::Home.new(school:).mentors_with_ects
    end
  end
end
