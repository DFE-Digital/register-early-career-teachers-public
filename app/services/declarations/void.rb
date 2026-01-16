module Declarations
  class Void
    attr_reader :author, :declaration, :voided_by_user_id

    def initialize(author:, declaration:, voided_by_user_id: nil)
      @author = author
      @declaration = declaration
      @voided_by_user_id = voided_by_user_id
    end

    def void
      ActiveRecord::Base.transaction do
        if voided_by_user_id
          declaration.voided_by_user_at = Time.current
          declaration.voided_by_user = User.find(voided_by_user_id)
        end

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
