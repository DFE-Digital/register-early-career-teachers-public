module API::Declarations
  class Clawback
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindDeclaration
    include API::FindLeadProvider
    include API::LeadProviderAuthor

    attribute :declaration_api_id
    attribute :lead_provider_id

    validate :declaration_is_refundable, if: -> { errors.empty? }

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

    def declaration_is_refundable
      return errors.add(:declaration_api_id, "The declaration must be paid before it can be clawed back") unless declaration.payment_status_paid?
      return errors.add(:declaration_api_id, "The declaration will or has been refunded") unless declaration.clawback_status_no_clawback?

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
