module Migration
  class ParticipantDeclaration < Migration::Base
    BILLABLE_STATES = %w[eligible payable paid].freeze
    REFUNDABLE_STATES = %w[awaiting_clawback clawed_back].freeze

    self.inheritance_column = :ignore

    belongs_to :participant_profile
    belongs_to :cpd_lead_provider
    belongs_to :cohort

    has_many :statement_line_items

    scope :not_superseded, -> { where(superseded_by_id: nil) }
    scope :not_ineligible, -> { where.not(state: "ineligible") }

    # state
    def billable? = BILLABLE_STATES.include?(state)

    def refundable? = REFUNDABLE_STATES.include?(state)

    def submitted? = state == "submitted"

    # status
    def clawback_status = refundable_line_item&.state || "no_clawback"

    def payment_status = billable_line_item&.state || "no_payment"

    # statements
    def clawback_statement = refundable_line_item&.statement

    def payment_statement = billable_line_item&.statement

    # type predicates
    def ect? = type == "ParticipantDeclaration::ECT"

  private

    def billable_line_item = @billable_line_item ||= statement_line_items.detect(&:billable?)

    def refundable_line_item = @refundable_line_item ||= statement_line_items.detect(&:refundable?)
  end
end
