module Schools::Mentors::ChangeNameWizard::Steps
  class EditStep
    include DfE::Wizard::Step

    delegate :state_store, to: :wizard

    attribute :name, :string

    validates :name,
              corrected_name: true,
              presence: { message: "Enter the correct full name" }

    validates :name,
              comparison: {
                other_than: ->(step) { step.state_store.old_name },
                case_sensitive: false,
                message: "The name must be different from the current name"
              }

    def self.permitted_params = %i[name]
  end
end
