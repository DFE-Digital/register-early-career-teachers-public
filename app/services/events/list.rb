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

    # @param appropriate_body [AppropriateBody]
    # @return [ActiveRecord::Relation<Event>]
    def for_appropriate_body(appropriate_body)
      scope.where(appropriate_body:)
    end
  end
end
