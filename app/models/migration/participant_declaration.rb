module Migration
  class ParticipantDeclaration < Migration::Base
    BILLABLE_STATES = %w[eligible payable paid voided].freeze
    REFUNDABLE_STATES = %w[awaiting_clawback clawed_back].freeze

    self.inheritance_column = :ignore

    belongs_to :participant_profile
    belongs_to :cpd_lead_provider
    belongs_to :cohort

    has_many :statement_line_items

    scope :not_superseded, -> { where(superseded_by_id: nil) }
    scope :not_ineligible, -> { where.not(state: "ineligible") }

    def billable? = BILLABLE_STATES.include?(state)

    def clawback_statement
      refundable_line_item&.statement if refundable?
    end

    def clawback_status = refundable? ? state : "no_clawback"

    def ect? = type == "ParticipantDeclaration::ECT"

    def payment_statement
      billable_line_item&.statement if refundable? || billable?
    end

    def payment_status
      return "no_payment" if submitted?
      return "paid" if refundable?

      state
    end

    def refundable? = REFUNDABLE_STATES.include?(state)

    def submitted? = state == "submitted"

  private

    def billable_line_item = @billable_line_item ||= statement_line_items.detect(&:billable?)

    def refundable_line_item = @refundable_line_item ||= statement_line_items.detect(&:refundable?)
  end
end
