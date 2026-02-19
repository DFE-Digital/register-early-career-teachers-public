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

    def started? = declaration_type == "started"

    def submitted? = state == "submitted"

    # status
    def clawback_status = refundable_line_item&.state || "no_clawback"

    def payment_status = billable_line_item&.state || "no_payment"

    # statements
    def clawback_statement = refundable_line_item&.statement

    def payment_statement = billable_line_item&.statement

    # others
    def ect? = type == "ParticipantDeclaration::ECT"

    def migrated_pupil_premium_uplift = migrated_uplift_flag(pupil_premium_uplift)
    def migrated_sparsity_uplift = migrated_uplift_flag(sparsity_uplift)

  private

    def billable_line_item = @billable_line_item ||= statement_line_items.detect(&:billable?)

    def migrated_uplift_flag(flag) = flag && started? && cohort.start_year < 2025

    def refundable_line_item = @refundable_line_item ||= statement_line_items.detect(&:refundable?)
  end
end
