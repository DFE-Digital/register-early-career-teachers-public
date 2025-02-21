module Schools
  class MentorsController < SchoolsController
    layout "full"

    def index
      @pagy, @mentors = pagy(Schools::Home.new(school:).mentors_with_ects, limit: 20)
    end
  end
end
