module Declarations
  class MentorCompletion
    attr_reader :author, :declaration

    def initialize(author:, declaration:)
      @author = author
      @declaration = declaration
    end

    def perform
      return false unless mentor_completion_event?

      ActiveRecord::Base.transaction do
        if latest_completed_declaration.billable_or_changeable?
          mentor_completed_training!
        else
          mentor_not_completed_training!
        end

        record_completion_change_event!
      end
    end

  private

    delegate :training_period, to: :declaration
    delegate :trainee, to: :training_period
    delegate :teacher, to: :trainee

    def mentor_completion_event?
      training_period.for_mentor? && declaration.declaration_type_completed?
    end

    def mentor_completed_training!
      teacher.update!(
        mentor_became_ineligible_for_funding_on: latest_completed_declaration.declaration_date,
        mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
      )
    end

    def mentor_not_completed_training!
      teacher.update!(
        mentor_became_ineligible_for_funding_on: nil,
        mentor_became_ineligible_for_funding_reason: nil
      )
    end

    def latest_completed_declaration
      @latest_completed_declaration ||= teacher
        .mentor_declarations
        .declaration_type_completed
        .order(declaration_date: :desc)
        .first!
    end

    def record_completion_change_event!
      return unless teacher.saved_changes?

      Events::Record.record_mentor_completion_status_change!(
        author:,
        teacher:,
        training_period:,
        declaration:,
        modifications: teacher.saved_changes
      )
    end
  end
end
