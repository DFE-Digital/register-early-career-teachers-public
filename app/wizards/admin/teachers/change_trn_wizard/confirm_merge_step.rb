module Admin
  module Teachers
    module ChangeTRNWizard
      class ConfirmMergeStep < Step
        class ProposedTRNChangedError < StandardError; end

        attribute :confirmed, :boolean
        attribute :expected_trn, :string

        validates :confirmed,
                  acceptance: {
                    message: "Confirm you want to merge these teacher records",
                    allow_nil: false
                  }

        def self.permitted_params = %i[confirmed expected_trn]

        def previous_step = :merge_preview

        def next_step = :records_merged

        def save!
          return false unless valid?

          if expected_trn.blank? || expected_trn != store.trn
            raise ProposedTRNChangedError
          end

          wizard.merge_trn!
          store.records_merged = true
          true
        end
      end
    end
  end
end
