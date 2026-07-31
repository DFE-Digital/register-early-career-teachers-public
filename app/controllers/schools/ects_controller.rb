module Schools
  class ECTsController < SchoolsController
    layout "full"

    include Schools::InductionRedirectable

    def index
      teachers_query = ECTAtSchoolPeriods::Query.new(
        school: @school,
        query_string: params[:q]
      )
      @pagy, @teachers = pagy(teachers_query.teachers)
      @number_of_teachers = teachers_query.teachers_count
    end

    def show
      @ect_at_school_period = @school.ect_at_school_periods.find(params[:id])
      @training_period = @ect_at_school_period.current_or_next_or_latest_training_period
      @teacher = @ect_at_school_period.teacher
    end
  end
end
