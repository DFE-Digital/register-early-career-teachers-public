module Declarations
  class Clawback
    attr_reader :author, :declaration, :voided_by_user_id, :next_available_output_fee_statement

    def initialize(author:, declaration:, next_available_output_fee_statement:, voided_by_user_id: nil)
      @author = author
      @declaration = declaration
      @voided_by_user_id = voided_by_user_id
      @next_available_output_fee_statement = next_available_output_fee_statement
    end

    def clawback
      ActiveRecord::Base.transaction do
        if voided_by_user_id
          declaration.voided_by_user_at = Time.current
          declaration.voided_by_user = User.find(voided_by_user_id)
        end

        attach_clawback_statement
        declaration.mark_as_awaiting_clawback!
        complete_mentor!
        record_clawback_event!
      end

      declaration
    end

  private

    def complete_mentor!
      MentorCompletion.new(author:, declaration:).perform
    end

    def attach_clawback_statement
      declaration.clawback_statement = next_available_output_fee_statement
    end

    def record_clawback_event!
      Events::Record.record_teacher_declaration_clawed_back!(
        author:,
        teacher: declaration.training_period.trainee.teacher,
        training_period: declaration.training_period,
        declaration:
      )
    end
  end
end
