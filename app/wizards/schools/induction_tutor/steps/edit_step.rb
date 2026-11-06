module Schools::InductionTutor::Steps
  class EditStep
    include DfE::Wizard::Step

    def self.permitted_params = %i[induction_tutor_name induction_tutor_email]

    attribute :induction_tutor_name, :string
    attribute :induction_tutor_email, :string

    validates :induction_tutor_name,
              presence: { message: "Enter the correct full name" },
              length: { maximum: 70, message: "Full name must be 70 letters or less" }

    validates :induction_tutor_email, notify_email: true, allow_blank: true

    validates :induction_tutor_email,
              presence: { message: "Enter an email address" },
              length: { maximum: 254, message: "Enter an email address that is less than 254 characters long" }
  end
end
