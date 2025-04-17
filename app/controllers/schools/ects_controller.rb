module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      @pagy, @teachers = pagy_array(Teachers::Search.new(ect_at_school: school).search)
    end

    def show
      # FIXME: restrict this to ECTAtSchoolPeriods belonging to the current school
      @ect = ::ECTAtSchoolPeriod.find(params[:id])
    end
  end
end
