module Schools
  class ECTsController < SchoolsController
    layout "full"

    def index
      search = Teachers::Search.new(ect_at_school: school, query_string: params[:q]).search
      @pagy, @filtered_teachers = pagy(search)

      @number_of_teachers = Teachers::Search.new(ect_at_school: school).count
    end

    def show
      @ect_at_school_period = @school.ect_at_school_periods.find(params[:id])
      @training_period = @ect_at_school_period.current_or_next_training_period
      @teacher = @ect_at_school_period.teacher
    end
  end
end
