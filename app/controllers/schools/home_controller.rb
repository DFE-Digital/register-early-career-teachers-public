module Schools
  class HomeController < SchoolsController
    layout "full"

    def index
      @ects = Schools::Home.new(school:).ects_and_mentors
    end
  end
end
