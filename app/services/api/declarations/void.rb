module API::Declarations
  class Void
    include API::Concerns::Declarations::SharedAction

    validate :not_already_voided
    validate :voidable_payment

    def void
      return false unless valid?

      Declarations::Void.new(author:, declaration:).void
    end

  private

    def not_already_voided
      return if errors[:declaration_api_id].any?
      return unless declaration.payment_status_voided?

      errors.add(:declaration_api_id, "The declaration has already been voided.")
    end

    def voidable_payment
      return if errors[:declaration_api_id].any?
      return if declaration.voidable_payment?

      # This error message might seem strange since the error isn't related to
      # whether the payment has been clawed back or not, but it is consistent
      # with ECF.
      errors.add(:declaration_api_id, "This declaration has been clawed-back, so you can only view it.")
    end
  end
end
