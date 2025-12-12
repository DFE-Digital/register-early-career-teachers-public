module API::Declarations
  class Void
    include ActiveModel::Model
    include ActiveModel::Attributes

    VOIDABLE_PAYMENT_STATUSES = %w[no_payment eligible payable ineligible].freeze

    attribute :declaration_id
    attribute :voided_by_user_id

    validate :not_voided
    validate :voidable, unless: :clawing_back?
    validate :not_already_refunded, if: :clawing_back?
    validate :output_fee_statement_available, if: :clawing_back?

    def clawback_or_void
      return false unless valid?

      if clawing_back?
        Declarations::Void.new.clawback
      else
        Declarations::Void.new.void
      end
    end

  private

    def declaration
      @declaration ||= Declaration.find_by!(api_id: declaration_id)
    end

    def clawing_back? = declaration.payment_status_paid?

    def not_voided
      return if errors[:declaration_id].any?
      return unless declaration.payment_status_voided?

      errors.add(:declaration_id, "The declaration has already been voided")
    end

    def voidable
      return if errors[:declaration_id].any?
      return if declaration.payment_status.in?(VOIDABLE_PAYMENT_STATUSES)

      voidable_error_message = <<~TXT.squish
        The declaration must have a payment status of
        #{VOIDABLE_PAYMENT_STATUSES.to_sentence(last_word_connector: 'or')}
      TXT
      errors.add(:declaration_id, voidable_error_message)
    end

    def not_already_refunded
      return if errors[:declaration_id].any?
      return if declaration.clawback_status_no_clawback?

      errors.add(:declaration_id, "The declaration has already been refunded")
    end

    def output_fee_statement_available
      return if errors[:declaration_id].any?
      return if output_fee_statements.exists?

      errors.add(:declaration_id, "The output fee statement is not available")
    end

    def output_fee_statements
      Statements::Search.new(
        lead_provider_id: declaration.training_period.lead_provider.id,
        contract_period_years: declaration.training_period.contract_period.year,
        fee_type: "output",
        deadline_date: Date.current..
      ).statements
    end
  end
end
