module Schools
  class MentorsController < SchoolsController
    layout "full"

    # TODO: increase the pagination limit to 20
    def index
      @pagy, @mentors = pagy(Schools::Home.new(school:).mentors_with_ects, limit: 2)
    end
  end
end
