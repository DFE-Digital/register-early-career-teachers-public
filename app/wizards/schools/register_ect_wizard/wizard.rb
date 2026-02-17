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
            cant_use_changed_email: CantUseChangedEmailStep,
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
        @allowed_steps ||= calculate_allowed_steps
      end

      def allowed_step?(step_name = current_step_name)
        allowed_steps.include?(step_name)
      end

      def ect
        @ect ||= RegistrationStore.new(store)
      end

      def step_for(step_name)
        self.class.new(
          current_step: step_name,
          author:,
          step_params: ActionController::Parameters.new,
          store:,
          school:
        ).current_step
      end

      def use_previous_choices_allowed?
        step = step_for(:use_previous_ect_choices)
        step.respond_to?(:allowed?) ? step.allowed? : true
      end

    private

      def calculate_allowed_steps
        return [:confirmation] if ect.registered?

        steps = %i[find_ect]

        # TRN must be present and teacher must be in TRS to proceed beyond find_ect
        return steps unless [ect.trn, ect.date_of_birth].all?(&:present?)
        return steps + %i[trn_not_found] unless ect.national_insurance_number || ect.in_trs?

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

        # Normal registration flow requires TRS data
        return steps if ect.trs_first_name.blank?

        steps << :review_ect_details
        return steps unless ect.change_name

        steps << :registered_before if ect.previously_registered?

        steps << :email_address
        return steps unless ect.email
        return steps + %i[cant_use_email] if ect.email_taken? && !can_reach_check_answers?

        steps << :start_date
        return steps unless ect.start_date

        return steps + %i[cannot_register_ect_yet] unless past_start_date? || start_date_contract_period&.enabled?

        steps << :working_pattern
        return steps unless ect.working_pattern

        if use_previous_choices_allowed?
          steps << :use_previous_ect_choices

          # `use_previous_ect_choices` is tri-state:
          # nil   → user has reached this step but has not yet answered,
          #         or has navigated back to change their answer
          # true  → user chose to reuse previous choices
          # false → user chose not to reuse
          if ect.use_previous_ect_choices.nil?
            if can_reach_check_answers?
              steps << :check_answers

              steps << :change_email_address
              return steps + %i[cant_use_changed_email] if ect.email_taken?

              steps << (school.independent? ? :change_independent_school_appropriate_body : :change_state_school_appropriate_body)

              steps << :change_training_programme
              steps << :training_programme_change_lead_provider if ect.provider_led? && (ect.was_school_led? || ect.lead_provider_id.nil?)

              steps << :change_lead_provider if ect.provider_led?
              steps << :change_review_ect_details
              steps << :change_start_date
              steps << :change_use_previous_ect_choices if use_previous_choices_allowed?
              steps << :change_working_pattern
            end

            return steps
          end
        end

        unless ect.use_previous_ect_choices && use_previous_choices_allowed?
          steps << if school.independent?
                     :independent_school_appropriate_body
                   else
                     :state_school_appropriate_body
                   end
          return steps unless ect.appropriate_body_id

          steps << :training_programme
          return steps unless ect.training_programme

          if ect.provider_led?
            steps << :lead_provider
            return steps unless ect.lead_provider_id || can_reach_check_answers?
          end
        end

        steps += %i[check_answers]

        # Only allow change steps if user has reached check_answers step
        steps << :change_email_address
        return steps + %i[cant_use_changed_email] if ect.email_taken?

        steps << (school.independent? ? :change_independent_school_appropriate_body : :change_state_school_appropriate_body)

        steps << :change_training_programme
        steps << :training_programme_change_lead_provider if ect.provider_led? && (ect.was_school_led? || ect.lead_provider_id.nil?)

        steps << :change_lead_provider if ect.provider_led?
        steps << :change_review_ect_details
        steps << :change_start_date
        steps << :change_use_previous_ect_choices if use_previous_choices_allowed?
        steps << :change_working_pattern

        # No previous choices change steps - only if school doesn't use previous choices
        unless ect.use_previous_ect_choices && use_previous_choices_allowed?
          steps << :no_previous_ect_choices_change_independent_school_appropriate_body if school.independent?
          steps << :no_previous_ect_choices_change_state_school_appropriate_body unless school.independent?
          steps << :no_previous_ect_choices_change_lead_provider if ect.provider_led?
          steps << :no_previous_ect_choices_change_training_programme
        end

        steps
      end

      def past_start_date?
        return false unless ect.start_date

        Date.parse(ect.start_date) <= Date.current
      end

      def start_date_contract_period
        return nil unless ect.start_date

        ContractPeriod.containing_date_end_inclusive(Date.parse(ect.start_date))
      end

      def can_reach_check_answers?
        # Check if user has basic required data to reach check_answers
        return false unless [ect.trn, ect.trs_first_name, ect.change_name, ect.email, ect.start_date, ect.working_pattern].all?(&:present?)

        # Check appropriate body requirements
        return false if ect.appropriate_body_id.blank?

        # Check training programme is selected
        return false if ect.training_programme.blank?

        true
      end
    end
  end
end
