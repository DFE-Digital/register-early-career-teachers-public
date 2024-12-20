module Builders
  class TeacherBase
    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end

    def process!
      raise NotImplementedError
    end

    def build
      process!
      true
    rescue => e
      ::TeacherMigrationFailure.create!(teacher:, message: e.message)
      false
    end
  end
end
