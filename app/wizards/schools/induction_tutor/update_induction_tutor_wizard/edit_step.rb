module Schools
  module InductionTutor
    module UpdateInductionTutorWizard
      class EditStep < InductionTutor::EditStep
        validate :details_must_be_changed

      private

        def details_must_be_changed
          if induction_tutor_email == school.induction_tutor_email &&
              induction_tutor_name == school.induction_tutor_name
            errors.add(:base, "You must change one of the fields to change the induction tutor details")
          end
        end
      end
    end
  end
end
