module Participants
  class Query
    attr_reader :scope

    def initialize
      @scope = all_participants
    end

    def participants
      scope.order(created_at: :asc)
    end

    def participant(id:)
      scope.where(id:)
    end

  private

    def all_participants
      # Union both queries and preload associations for serialization
      Teacher
        .select("teachers.*")
        .from("(#{ect_teachers.to_sql} UNION #{mentor_teachers.to_sql}) as teachers")
        .includes(
          ect_at_school_periods: [
            { training_periods: [:lead_provider, { latest_mentorship_period: :mentor }] },
            { latest_mentorship_period: :mentor }
          ],
          mentor_at_school_periods: [
            { training_periods: :lead_provider }
          ]
        )
    end

    def ect_teachers
      Teacher
        .select("teachers.*")
        .joins(ect_at_school_periods: { training_periods: :lead_provider })
    end

    def mentor_teachers
      Teacher
        .select("teachers.*")
        .joins(mentor_at_school_periods: { training_periods: :lead_provider })
    end
  end
end
