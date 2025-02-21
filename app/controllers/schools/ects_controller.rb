module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      @ects = Schools::Home.new(school:).ects_with_mentors
    end

    def show
      @ect = ::ECTAtSchoolPeriod.find(params[:id])
    end
  end
end
