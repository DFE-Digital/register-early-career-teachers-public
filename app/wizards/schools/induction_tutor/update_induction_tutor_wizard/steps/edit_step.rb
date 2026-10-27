module Schools::InductionTutor::UpdateInductionTutorWizard::Steps
  class EditStep < Schools::InductionTutor::Steps::EditStep
    validate :details_must_be_changed

  private

    def details_must_be_changed
      if induction_tutor_email == wizard.school.induction_tutor_email &&
          induction_tutor_name == wizard.school.induction_tutor_name
        errors.add(:base, "You must change one of the fields to change the induction tutor details")
      end
    end
  end
end
