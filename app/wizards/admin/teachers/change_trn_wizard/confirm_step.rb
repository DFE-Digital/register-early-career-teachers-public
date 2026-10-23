module Admin
  module Teachers
    module ChangeTRNWizard
      class ConfirmStep < Step
        class ProposedTRNChangedError < StandardError; end

        attribute :confirmed, :boolean
        attribute :expected_trn, :string

        validates :confirmed,
                  acceptance: {
                    message: "Confirm you want to change this teacher’s TRN",
                    allow_nil: false
                  }

        def self.permitted_params = %i[confirmed expected_trn]

        def previous_step = :enter_trn

        def next_step = :confirmation

        def save!
          return false unless valid?

          if expected_trn.blank? || expected_trn != store.trn
            raise ProposedTRNChangedError
          end

          wizard.replace_trn!
          store.trn_replaced = true
          true
        end
      end
    end
  end
end
