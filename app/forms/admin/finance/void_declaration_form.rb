module Admin
  module Finance
    class VoidDeclarationForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :declaration
      attribute :author
      attribute :confirmed, :boolean

      validates :confirmed, acceptance: { message: "Confirm you want to void this declaration", allow_nil: false }

      validate :clawback_statement_available, if: :paid_declaration?

      def void!
        return false unless valid?

        if paid_declaration?
          clawback_service.clawback
        else
          void_service.void
        end
      end

    private

      def paid_declaration?
        declaration&.payment_status_paid?
      end

      def clawback_statement_available
        return if clawback_service.next_available_output_fee_statement.present?

        errors.add(:base, "This declaration has been paid, and no future statement exists for clawback")
      end

      def clawback_service
        @clawback_service ||= Declarations::Clawback.new(**service_attributes)
      end

      def void_service
        @void_service ||= Declarations::Void.new(**service_attributes)
      end

      def service_attributes
        {
          author:,
          declaration:,
          voided_by_user_id: author&.id
        }
      end
    end
  end
end
