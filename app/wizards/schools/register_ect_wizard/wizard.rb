# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class Wizard < DfE::Wizard::Base
      attr_accessor :store, :school

      steps do
        [
          {
            already_active_at_school: AlreadyActiveAtSchoolStep,
            cannot_register_ect: CannotRegisterECTStep,
            cant_use_email: CantUseEmailStep,
            change_email_address: ChangeEmailAddressStep,
            change_independent_school_appropriate_body: ChangeIndependentSchoolAppropriateBodyStep,
            change_lead_provider: ChangeLeadProviderStep,
            change_programme_type: ChangeProgrammeTypeStep,
            change_review_ect_details: ChangeReviewECTDetailsStep,
            change_start_date: ChangeStartDateStep,
            change_state_school_appropriate_body: ChangeStateSchoolAppropriateBodyStep,
            change_working_pattern: ChangeWorkingPatternStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
            email_address: EmailAddressStep,
            find_ect: FindECTStep,
            independent_school_appropriate_body: IndependentSchoolAppropriateBodyStep,
            induction_completed: InductionCompletedStep,
            induction_exempt: InductionExemptStep,
            lead_provider: LeadProviderStep,
            national_insurance_number: NationalInsuranceNumberStep,
            not_found: NotFoundStep,
            programme_type: ProgrammeTypeStep,
            review_ect_details: ReviewECTDetailsStep,
            start_date: StartDateStep,
            state_school_appropriate_body: StateSchoolAppropriateBodyStep,
            trn_not_found: TRNNotFoundStep,
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

      def appropriate_bodies
        @appropriate_bodies ||= AppropriateBody.select(:id, :name).all
      end

      # OPTIMIZE: May eventually depend on the ECT being registered and move to Schools::RegisterECTWizard::ECT
      def lead_providers
        @lead_providers ||= LeadProvider.select(:id, :name).all
      end
    end
  end
end
