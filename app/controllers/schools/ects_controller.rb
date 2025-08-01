module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      search = Teachers::Search.new(ect_at_school: school, query_string: params[:q]).search
      @pagy, @filtered_teachers = pagy(search)

      @number_of_teachers = Teachers::Search.new(ect_at_school: school).count
    end

    def show
      # FIXME: restrict this to ECTAtSchoolPeriods belonging to the current school
      @ect = ::ECTAtSchoolPeriod.find(params[:id])
    end
  end
end
