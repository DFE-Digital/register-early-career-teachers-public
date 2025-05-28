module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      query = params[:q].presence
      teachers = Teachers::Search.new(ect_at_school: school, query_string: query)
      results = teachers.search

      @pagy, @filtered_teachers = pagy_array(results)
      @has_any_teachers = query ? Teachers::Search.new(ect_at_school: school).scope.exists? : results.any?
    end

    def show
      # FIXME: restrict this to ECTAtSchoolPeriods belonging to the current school
      @ect = ::ECTAtSchoolPeriod.find(params[:id])
    end
  end
end
