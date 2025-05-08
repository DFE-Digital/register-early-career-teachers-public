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

    def participant(id: nil)
      scope.where(id:)
    end

  private

    def all_participants
      TrainingPeriod.from("(#{ect_participants.to_sql} UNION #{mentor_participants.to_sql}) as training_periods")
    end

    def ect_participants
      TrainingPeriod
        .joins("JOIN (#{latest_ect_training_periods_join.to_sql}) AS latest_ect_training_periods_join ON latest_ect_training_periods_join.latest_id = training_periods.id")
    end

    def mentor_participants
      TrainingPeriod
        .joins("JOIN (#{latest_mentor_training_periods_join.to_sql}) AS latest_mentor_training_periods_join ON latest_mentor_training_periods_join.latest_id = training_periods.id")
    end

    def latest_ect_training_periods_join
      TrainingPeriod
      .select(Arel.sql("DISTINCT FIRST_VALUE(training_periods.id) OVER (#{latest_ect_training_period_order}) AS latest_id"))
      .joins(:school_partnership)
      .merge!(SchoolPartnership.for_lead_provider(lead_provider.id))
    end

    def latest_mentor_training_periods_join
      TrainingPeriod
      .select(Arel.sql("DISTINCT FIRST_VALUE(training_periods.id) OVER (#{latest_mentor_training_period_order}) AS latest_id"))
      .joins(:school_partnership)
      .merge!(SchoolPartnership.for_lead_provider(lead_provider.id))
    end

    def latest_ect_training_period_order
      <<~SQL
        PARTITION BY(training_periods.ect_at_school_period_id) ORDER BY
          CASE
            WHEN training_periods.finished_on IS NULL
              THEN 1
            ELSE 2
          END,
          training_periods.started_on DESC,
          training_periods.created_at DESC
      SQL
    end

    def latest_mentor_training_period_order
      <<~SQL
        PARTITION BY(training_periods.mentor_at_school_period_id) ORDER BY
          CASE
            WHEN training_periods.finished_on IS NULL
              THEN 1
            ELSE 2
          END,
          training_periods.started_on DESC,
          training_periods.created_at DESC
      SQL
    end
  end
end
