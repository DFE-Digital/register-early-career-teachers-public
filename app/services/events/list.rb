module Events
  # Event filtering for timelines.
  class List
    attr_accessor :scope

    def initialize
      @scope = Event.latest_first
    end

    # @return [ActiveRecord::Relation<Event>]
    def events = scope

    # @param teacher [Teacher]
    # @return [Events::List]
    def for_teacher(teacher)
      scope.merge!(scope.where(teacher:))

      self
    end

    # @param school [School]
    # @return [Events::List]
    def for_school(school)
      scope.merge!(scope.where(school:))

      self
    end

    # @param appropriate_body_period [AppropriateBodyPeriod]
    # @return [Events::List]
    def for_appropriate_body_period(appropriate_body_period)
      scope.merge!(scope.where(appropriate_body_period:))

      self
    end
  end
end
