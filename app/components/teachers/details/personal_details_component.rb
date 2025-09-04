module Teachers::Details
  class PersonalDetailsComponent < ApplicationComponent
    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end
  end
end
