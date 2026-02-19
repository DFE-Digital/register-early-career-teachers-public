module Declarations
  class Clawback
    include ActiveModel::Model

    attr_reader :author, :declaration, :voided_by_user_id

    validates :next_available_output_fee_statement, presence: true

    def initialize(author:, declaration:, voided_by_user_id: nil)
      @author = author
      @declaration = declaration
      @voided_by_user_id = voided_by_user_id
    end

    def clawback
      return false unless valid?

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

    def next_available_output_fee_statement
      @next_available_output_fee_statement ||= Statements::Search
        .new(
          lead_provider_id: lead_provider.id,
          contract_period_years: contract_period.year,
          fee_type: "output",
          deadline_date: Date.current..,
          order: :deadline_date
        )
        .statements
        .first
    end

  private

    delegate :training_period, to: :declaration
    delegate :contract_period, :lead_provider, to: :training_period

    def complete_mentor!
      MentorCompletion.new(author:, declaration:).perform
    end

    def attach_clawback_statement
      declaration.clawback_statement = next_available_output_fee_statement
    end

    def record_clawback_event!
      Events::Record.record_teacher_declaration_awaiting_clawback!(
        author:,
        teacher: declaration.training_period.teacher,
        training_period: declaration.training_period,
        declaration:
      )
    end
  end
end
