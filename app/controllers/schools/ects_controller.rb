module Schools
  class ECTsController < SchoolsController
    layout "full"

    include Schools::InductionRedirectable

    def index
      search = Teachers::Search
        .new(
          ect_at_school: school,
          in_progress: true,
          query_string: params[:q]
        )
        .search
        .preload( # .includes folds into search query and breaks when no current/next TP
          ongoing_induction_period: :appropriate_body_period,
          ect_at_school_periods: %i[latest_training_period mentorship_periods],
          current_or_next_ect_at_school_period: [
            { current_or_next_training_period: %i[
              lead_provider
              delivery_partner
              expression_of_interest_lead_provider
            ] },
            { latest_training_period: %i[
              lead_provider
              delivery_partner
              expression_of_interest_lead_provider
            ] },
            { current_or_next_mentorship_period: { mentor: :teacher } }
          ]
        )
      @pagy, @teachers = pagy(search)

      @number_of_teachers = Teachers::Search.new(ect_at_school: school, in_progress: true).count
    end

    def show
      @ect_at_school_period = @school.ect_at_school_periods.find(params[:id])
      @training_period = @ect_at_school_period.current_or_next_or_latest_training_period
      @teacher = @ect_at_school_period.teacher
    end
  end
end
