module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      search = Teachers::Search.new(ect_at_school: school, query_string: params[:q]).search
      @pagy, @filtered_teachers = pagy(search)

      @number_of_teachers = Teachers::Search.new(ect_at_school: school).count
    end

    def show
      @ect_at_school_period = ::ECTAtSchoolPeriod.find_by!(id: params[:id], school_id: school.id)
      @teacher = @ect_at_school_period.teacher
    end
  end
end
