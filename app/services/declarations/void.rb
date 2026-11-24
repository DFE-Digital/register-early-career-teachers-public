module Declarations
  class Void
    attr_reader :author, :declaration

    def initialize(author:, declaration:)
      @author = author
      @declaration = declaration
    end

    def void
      ActiveRecord::Base.transaction do
        declaration.mark_as_voided!
        complete_mentor!
        record_void_event!
      end

      declaration
    end

  private

    def complete_mentor!
      MentorCompletion.new(author:, declaration:).perform
    end

    def record_void_event!
      Events::Record.record_teacher_declaration_voided!(
        author:,
        teacher: declaration.training_period.teacher,
        training_period: declaration.training_period,
        declaration:
      )
    end
  end
end
