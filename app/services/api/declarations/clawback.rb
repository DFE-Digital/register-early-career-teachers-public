module API::Declarations
  class Clawback
    include API::Concerns::Declarations::SharedAction

    validate :paid
    validate :not_already_refunded
    validate :output_fee_statement_available

    def clawback
      return false unless valid?

      clawback_service.clawback
    end

  private

    def clawback_service
      @clawback_service ||= Declarations::Clawback.new(
        author:,
        declaration:
      )
    end

    def paid
      return if errors[:declaration_api_id].any?
      return if declaration.payment_status_paid?

      errors.add(:declaration_api_id, "The declaration must be paid before it can be clawed back")
    end

    def not_already_refunded
      return if errors[:declaration_api_id].any?
      return if declaration.clawback_status_no_clawback?

      errors.add(:declaration_api_id, "The declaration will or has been refunded")
    end

    def output_fee_statement_available
      return if errors[:declaration_api_id].any?
      return if clawback_service.next_available_output_fee_statement.present?

      no_output_fee_statement_error_message = <<~TXT.squish
        You cannot submit or void declarations for the #{contract_period_year}
        contract period. The funding contract for this contract period has
        ended. Get in touch if you need to discuss this with us
      TXT
      errors.add(:declaration_api_id, no_output_fee_statement_error_message)
    end

    def contract_period_year = declaration.training_period.contract_period.year
  end
end
