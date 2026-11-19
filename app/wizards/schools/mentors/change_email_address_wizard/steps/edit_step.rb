module Schools::Mentors::ChangeEmailAddressWizard::Steps
  class EditStep
    include DfE::Wizard::Step

    attribute :email, :string

    delegate :mentor_at_school_period, :state_store, to: :wizard

    validates :email,
              presence: { message: "Enter an email address" }

    validates :email, notify_email: true, allow_blank: true

    validates :email,
              length: {
                maximum: 254,
                message: "Enter an email address that is less than 254 characters long"
              },
              allow_blank: true

    validates :email,
              comparison: {
                other_than: ->(record) { record.state_store.original_email },
                case_sensitive: false,
                message: "The email must be different from the current email"
              },
              allow_blank: true

    def self.permitted_params = %i[email]
  end
end
