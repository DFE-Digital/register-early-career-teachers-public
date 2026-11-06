module Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Steps
  class EditStep
    include DfE::Wizard::Step

    def self.permitted_params = %i[are_these_details_correct induction_tutor_name induction_tutor_email]

    attribute :are_these_details_correct, :boolean
    attribute :induction_tutor_name, :string
    attribute :induction_tutor_email, :string

    validates :are_these_details_correct,
              inclusion: { in: [true, false], message: "Select 'Yes' or 'No, someone else will be the induction tutor'" }

    validate :details_must_be_changed_unless_confirmed

    validates :induction_tutor_name,
              presence: { message: "Enter the correct full name" },
              length: { maximum: 70, message: "Full name must be 70 letters or less" }, unless: :are_these_details_correct

    validates :induction_tutor_email, notify_email: true, allow_blank: true

    validates :induction_tutor_email,
              presence: { message: "Enter an email address" },
              length: { maximum: 254, message: "Enter an email address that is less than 254 characters long" }, unless: :are_these_details_correct

  private

    def details_must_be_changed_unless_confirmed
      return if are_these_details_correct

      if induction_tutor_name == wizard.school.induction_tutor_name &&
          induction_tutor_email == wizard.school.induction_tutor_email
        errors.add(:base, "You must change the induction tutor details or confirm they are correct")
      end
    end
  end
end
