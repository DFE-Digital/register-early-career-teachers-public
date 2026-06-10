module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriodWizard
        class SelectPartnershipStep < Step
          attribute :school_partnership_id, :integer

          validates :school_partnership_id, presence: { message: "Select a partnership" }
          validate :school_partnership_available

          def self.permitted_params = %i[school_partnership_id]

          def previous_step = :select_contract_period

        private

          def persist
            value = step_params["school_partnership_id"] || school_partnership_id
            store.school_partnership_id = value
          end

          def school_partnership_available
            return if school_partnership_id.blank?
            return if wizard.school_partnerships.where(id: school_partnership_id).exists?

            errors.add(:school_partnership_id, "Select a partnership")
          end
        end
      end
    end
  end
end
