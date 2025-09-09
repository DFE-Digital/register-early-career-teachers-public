module Teachers::Details
  class ITTDetailsComponent < ApplicationComponent
    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end
  end
end
