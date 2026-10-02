module Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Steps
  class SelectPartnershipStep
    include DfE::Wizard::Step

    def self.permitted_params = %i[school_partnership_id]

    attribute :school_partnership_id, :integer

    validates :school_partnership_id, presence: { message: "Select a partnership" }
    validate :school_partnership_available

    delegate :state_store, to: :wizard

  private

    def school_partnership_available
      return if school_partnership_id.blank?
      return if state_store.school_partnerships.exists?(id: school_partnership_id)

      errors.add(:school_partnership_id, "Select a partnership")
    end
  end
end
