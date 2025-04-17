module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      @pagy, @teachers = pagy_array(Teachers::Search.new(ect_at_school: school).search)
    end

    def show
      @ect = ::ECTAtSchoolPeriod.find(params[:id])
    end
  end
end
