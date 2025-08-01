# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class Wizard < DfE::Wizard::Base
      attr_accessor :store, :school, :author

      steps do
        [
          {
            already_active_at_school: AlreadyActiveAtSchoolStep,
            cannot_register_ect: CannotRegisterECTStep,
            cannot_register_ect_yet: CannotRegisterECTYetStep,
            cant_use_email: CantUseEmailStep,
            change_email_address: ChangeEmailAddressStep,
            change_independent_school_appropriate_body: ChangeIndependentSchoolAppropriateBodyStep,
            change_lead_provider: ChangeLeadProviderStep,
            change_training_programme: ChangeTrainingProgrammeStep,
            change_review_ect_details: ChangeReviewECTDetailsStep,
            change_start_date: ChangeStartDateStep,
            change_state_school_appropriate_body: ChangeStateSchoolAppropriateBodyStep,
            change_use_previous_ect_choices: ChangeUsePreviousECTChoicesStep,
            change_working_pattern: ChangeWorkingPatternStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
            email_address: EmailAddressStep,
            find_ect: FindECTStep,
            independent_school_appropriate_body: IndependentSchoolAppropriateBodyStep,
            induction_completed: InductionCompletedStep,
            induction_exempt: InductionExemptStep,
            induction_failed: InductionFailedStep,
            lead_provider: LeadProviderStep,
            national_insurance_number: NationalInsuranceNumberStep,
            no_previous_ect_choices_change_independent_school_appropriate_body: NoPreviousECTChoicesChangeIndependentSchoolAppropriateBodyStep,
            no_previous_ect_choices_change_lead_provider: NoPreviousECTChoicesChangeLeadProviderStep,
            no_previous_ect_choices_change_training_programme: NoPreviousECTChoicesChangeTrainingProgrammeStep,
            no_previous_ect_choices_change_state_school_appropriate_body: NoPreviousECTChoicesChangeStateSchoolAppropriateBodyStep,
            not_found: NotFoundStep,
            training_programme: TrainingProgrammeStep,
            training_programme_change_lead_provider: TrainingProgrammeChangeLeadProviderStep,
            review_ect_details: ReviewECTDetailsStep,
            registered_before: RegisteredBeforeStep,
            start_date: StartDateStep,
            state_school_appropriate_body: StateSchoolAppropriateBodyStep,
            trn_not_found: TRNNotFoundStep,
            use_previous_ect_choices: UsePreviousECTChoicesStep,
            working_pattern: WorkingPatternStep,
          }
        ]
      end

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      delegate :save!, to: :current_step
      delegate :reset, to: :ect

      def ect
        @ect ||= ECT.new(store)
      end
    end
  end
end
