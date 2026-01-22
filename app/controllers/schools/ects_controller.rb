module Schools
  class ECTsController < SchoolsController
    layout "full"

    include Schools::InductionRedirectable

    def index
      search = Teachers::Search.new(ect_at_school: school, query_string: params[:q]).search
      @pagy, @teachers = pagy(search)

      @number_of_teachers = Teachers::Search.new(ect_at_school: school).count
      @blocked_from_registering_new_ects = school.blocked_from_registering_new_ects?
    end

    def show
      @ect_at_school_period = @school.ect_at_school_periods.find(params[:id])
      @training_period = @ect_at_school_period.current_or_next_training_period
      @teacher = @ect_at_school_period.teacher
    end
  end
end
