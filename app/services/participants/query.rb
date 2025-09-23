module Participants
  class Query
    attr_reader :scope, :lead_provider

    def initialize(lead_provider:)
      @lead_provider = lead_provider
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
          :lead_provider_metadata,
          ect_at_school_periods: { training_periods: :lead_provider },
          mentor_at_school_periods: { training_periods: :lead_provider }
        )
    end

    def ect_teachers
      Teacher
        .select("teachers.*")
        .joins(ect_at_school_periods: { training_periods: :lead_provider })
        .where(lead_providers: { id: lead_provider.id })
    end

    def mentor_teachers
      Teacher
        .select("teachers.*")
        .joins(mentor_at_school_periods: { training_periods: :lead_provider })
        .where(lead_providers: { id: lead_provider.id })
    end
  end
end
