module Schools
  module RegisterECTWizard
    class Wizard < ApplicationWizard
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

      def allowed_steps
        @allowed_steps ||=
          begin
            return [:confirmation] if ect.ect_at_school_period_id.present?

            steps = %i[find_ect]
            # Only check TRS status if we have a TRN - allows test scenarios that skip find_ect
            if ect.trn.present? && !ect.in_trs?
              return steps + %i[trn_not_found]
            end

            # Only check TRS-dependent validations if we have TRS data
            if ect.trn.present? && ect.trs_date_of_birth.present?
              unless ect.matches_trs_dob?
                steps << :national_insurance_number
                return steps unless ect.national_insurance_number
                # After national insurance number is provided, check if teacher is still in TRS
                return steps + %i[not_found] unless ect.in_trs?
              end

              return steps + %i[already_active_at_school] if ect.active_at_school?(school.urn)
              return steps + %i[induction_completed] if ect.induction_completed?
              return steps + %i[induction_exempt] if ect.induction_exempt?
              return steps + %i[induction_failed] if ect.induction_failed?
              return steps + %i[cannot_register_ect] if ect.prohibited_from_teaching?
            end

            # Check prohibited from teaching even without full TRS data
            return steps + %i[cannot_register_ect] if ect.prohibited_from_teaching?

            # If we have TRS data, require the normal flow
            if ect.trn.present? && ect.trs_first_name.present?
              steps << :review_ect_details
              return steps unless ect.change_name

              steps << :registered_before if ect.previously_registered?

              steps << :email_address
              return steps unless ect.email
              return steps + %i[cant_use_email] if ect.cant_use_email?
            end

            steps << :start_date
            return steps unless ect.start_date

            steps << :working_pattern
            return steps unless ect.working_pattern

            if school.last_programme_choices?
              steps << :use_previous_ect_choices
              return steps + %i[check_answers] if ect.use_previous_ect_choices
            end

            steps << if school.independent?
                       :independent_school_appropriate_body
                     else
                       :state_school_appropriate_body
                     end

            return steps unless ect.appropriate_body_id

            steps << :training_programme
            return steps unless ect.training_programme

            steps << :lead_provider if ect.provider_led?
            return steps unless ect.lead_provider_id || ect.school_led?

            steps += %i[check_answers]

            # Always allow change steps for completed flows
            steps += %i[
              change_email_address
              change_independent_school_appropriate_body
              change_lead_provider
              change_training_programme
              change_review_ect_details
              change_start_date
              change_state_school_appropriate_body
              change_use_previous_ect_choices
              change_working_pattern
              training_programme_change_lead_provider
              no_previous_ect_choices_change_independent_school_appropriate_body
              no_previous_ect_choices_change_lead_provider
              no_previous_ect_choices_change_training_programme
              no_previous_ect_choices_change_state_school_appropriate_body
            ]

            steps
          end
      end

      def ect
        @ect ||= ECT.new(store)
      end
    end
  end
end
