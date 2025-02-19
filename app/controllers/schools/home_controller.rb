module Schools
  class HomeController < SchoolsController
    layout "full"

    def index
      @ects = Schools::Home.new(school:).ects_with_mentors
    end
  end
end
