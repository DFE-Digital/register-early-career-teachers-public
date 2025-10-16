module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class EditStep < Step
        attribute :email, :string

        validates :email,
          presence: {message: "Enter an email address"}

        validates :email, notify_email: true, allow_blank: true

        validates :email,
          length: {
            maximum: 254,
            message: "Enter an email address that is less than 254 characters long"
          },
          allow_blank: true

        validates :email,
          comparison: {
            other_than: ->(record) { record.mentor_at_school_period.email },
            case_sensitive: false,
            message: "The email must be different from the current email"
          },
          allow_blank: true

        def self.permitted_params = [:email]

        def next_step = :check_answers

        def save!
          store.email = email if valid_step?
        end

        private

        def pre_populate_attributes
          self.email = store.email.presence || mentor_at_school_period.email
        end
      end
    end
  end
end
