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
        allowed_steps.include?(step_name) || always_allowed_step?(step_name)
      end

      def ect
        @ect ||= ECT.new(store)
      end

    private

      def calculate_allowed_steps
        return [:confirmation] if ect.registered?

        steps = %i[find_ect]

        # TRN must be present and teacher must be in TRS to proceed beyond find_ect
        return steps if ect.trn.blank?
        return steps + %i[trn_not_found] unless ect.in_trs?

        # If TRS data is present, check for blocking conditions
        if ect.trs_date_of_birth.present?
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

        # Normal registration flow requires TRS data
        return steps if ect.trs_first_name.blank?

        steps << :review_ect_details
        return steps unless ect.change_name

        steps << :registered_before if ect.previously_registered?

        steps << :email_address
        return steps unless ect.email
        return steps + %i[cant_use_email] if ect.cant_use_email? && !ect.start_date

        steps << :start_date
        return steps unless ect.start_date

        return steps + %i[cannot_register_ect_yet] unless past_start_date? || start_date_contract_period&.enabled?

        steps << :working_pattern
        return steps unless ect.working_pattern

        if school.last_programme_choices?
          steps << :use_previous_ect_choices
          return steps if ect.use_previous_ect_choices.nil?
        end

        unless school.last_programme_choices? && ect.use_previous_ect_choices
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
            return steps unless ect.lead_provider_id
          end
        end

        steps += %i[check_answers]

        # Always allow change steps for completed flows
        steps << :change_email_address
        return steps + %i[cant_use_changed_email] if ect.cant_use_email?

        steps << (school.independent? ? :change_independent_school_appropriate_body : :change_state_school_appropriate_body)

        steps << :change_training_programme
        steps << :training_programme_change_lead_provider if !ect.school_led? && (ect.was_school_led? || ect.lead_provider_id.nil?)

        steps += %i[
          change_lead_provider
          change_review_ect_details
          change_start_date
          change_use_previous_ect_choices
          change_working_pattern
          no_previous_ect_choices_change_independent_school_appropriate_body
          no_previous_ect_choices_change_lead_provider
          no_previous_ect_choices_change_training_programme
          no_previous_ect_choices_change_state_school_appropriate_body
        ]

        steps
      end

      # Change steps and error steps are always allowed
      def always_allowed_step?(step_name)
        step_name = step_name.to_s
        step_name.start_with?('change_', 'no_previous_ect_choices_change_', 'training_programme_change_') ||
          step_name.in?(%w[not_found trn_not_found induction_completed induction_exempt induction_failed cannot_register_ect already_active_at_school cant_use_email cant_use_changed_email])
      end

      def past_start_date?
        return false unless ect.start_date

        Date.parse(ect.start_date) <= Date.current
      end

      def start_date_contract_period
        return nil unless ect.start_date

        ContractPeriod.containing_date(Date.parse(ect.start_date))
      end
    end
  end
end
