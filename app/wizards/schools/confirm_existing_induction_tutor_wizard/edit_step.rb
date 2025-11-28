module Schools
  module ConfirmExistingInductionTutorWizard
    class EditStep < Step
      attribute :induction_tutor_email, :string
      attribute :induction_tutor_name, :string
      attribute :are_these_details_correct, :boolean

      validates :induction_tutor_email,
                presence: { message: "Email cannot be blank" }

      validates :induction_tutor_name,
                presence: { message: "Name cannot be blank" }

      validates :are_these_details_correct,
                inclusion: { in: [true, false], message: "Select 'Yes' if these details are correct" }

      validate :details_must_be_changed_unless_confirmed

      def self.permitted_params = %i[
        school_id
        induction_tutor_name
        induction_tutor_email
        are_these_details_correct
      ]

      def next_step
        if are_these_details_correct
          :confirmation
        else
          :check_answers
        end
      end

      def save!
        store.induction_tutor_email = induction_tutor_email if valid_step?
        store.induction_tutor_name = induction_tutor_name if valid_step?
      end

    private

      def pre_populate_attributes
        self.induction_tutor_email = store.induction_tutor_email.presence || school.induction_tutor_email
        self.induction_tutor_name = store.induction_tutor_name.presence || school.induction_tutor_name
      end

      def details_must_be_changed_unless_confirmed
        return if are_these_details_correct

        if induction_tutor_email == school.induction_tutor_email &&
            induction_tutor_name == school.induction_tutor_name
          errors.add(:base, "You must change the induction tutor details or confirm they are correct")
        end
      end
    end
  end
end
