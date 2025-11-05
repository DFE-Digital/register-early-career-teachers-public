module Events
  # Event filtering for timelines.
  class List
    attr_accessor :scope

    def initialize
      @scope = Event.latest_first
    end

    # @param teacher [Teacher]
    # @return [ActiveRecord::Relation<Event>]
    def for_teacher(teacher)
      scope.where(teacher:)
    end

    # @param appropriate_body_period [AppropriateBodyPeriod]
    # @return [ActiveRecord::Relation<Event>]
    def for_appropriate_body_period(appropriate_body_period)
      scope.where(appropriate_body_period:)
    end
  end
end
