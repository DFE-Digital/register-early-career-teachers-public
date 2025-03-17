module Events
  class List
    attr_accessor :scope

    def initialize
      @scope = Event.latest_first
    end

    def for_teacher(teacher)
      scope.where(teacher:)
    end
  end
end
