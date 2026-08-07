module Schools::ECTs
  class TeachersQuery
    def initialize(school:, query_string:)
      @school = school
      @query_string = query_string
    end

    def teachers
      teachers_search
        .search
        .strict_loading
        .preload(
          ongoing_induction_period: :appropriate_body_period,
          current_or_next_ect_at_school_period: [
            :school,
            :school_reported_appropriate_body,
            {
              current_or_next_mentorship_period: { mentor: :teacher },
              upcoming_mentorship_periods: { mentor: :teacher },
              current_or_next_training_period: %i[
                lead_provider
                expression_of_interest
                expression_of_interest_lead_provider
                delivery_partner
              ],
              latest_training_period: %i[
                lead_provider
                expression_of_interest
                expression_of_interest_lead_provider
                delivery_partner
              ]
            }
          ]
        )
    end

    def total_teachers_count
      Teachers::Search.new(ect_at_school: @school, in_progress: true).count
    end

  private

    def teachers_search
      Teachers::Search.new(ect_at_school: @school, in_progress: true, query_string: @query_string)
    end
  end
end
