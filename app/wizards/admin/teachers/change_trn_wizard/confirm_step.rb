module Admin
  module Teachers
    module ChangeTRNWizard
      class ConfirmStep < Step
        class ProposedTRNChangedError < StandardError; end

        delegate :merge_proposed?, to: :wizard

        attribute :confirmed, :boolean
        attribute :expected_trn, :string

        validates :confirmed,
                  acceptance: {
                    message: ->(step, _) { step.confirmation_message },
                    allow_nil: false
                  }

        def self.permitted_params = %i[confirmed expected_trn]

        def previous_step
          merge_proposed? ? :merge_preview : :enter_trn
        end

        def next_step = :confirmation

        def save!
          return false unless valid?

          raise ProposedTRNChangedError unless reviewed_trn_matches_proposal?

          wizard.update!

          true
        end

        def confirmation_message
          if merge_proposed?
            "Confirm you want to merge these teacher records"
          else
            "Confirm you want to change this teacher’s TRN"
          end
        end

      private

        def reviewed_trn_matches_proposal?
          expected_trn.present? && expected_trn == store.trn
        end
      end
    end
  end
end
