module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      @teachers = Teachers::Search.new(ect_at_school: school).search
      @pagy, @filtered_teachers = pagy_array(Teachers::Search.new(ect_at_school: school, query_string: params[:q]).search)
    end

    def show
      # FIXME: restrict this to ECTAtSchoolPeriods belonging to the current school
      @ect = ::ECTAtSchoolPeriod.find(params[:id])
    end
  end
end
