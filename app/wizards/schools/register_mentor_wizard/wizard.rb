module Schools
  module RegisterMentorWizard
    class Wizard < ApplicationWizard
      attr_accessor :store, :ect_id, :author

      steps do
        [
          {
            already_active_at_school: AlreadyActiveAtSchoolStep,
            cannot_mentor_themself: CannotMentorThemselfStep,
            cannot_register_mentor: CannotRegisterMentorStep,
            cant_use_changed_email: CantUseChangedEmailStep,
            cant_use_email: CantUseEmailStep,
            change_email_address: ChangeEmailAddressStep,
            change_lead_provider: ChangeLeadProviderStep,
            change_mentor_details: ChangeMentorDetailsStep,
            change_started_on: ChangeStartedOnStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
            eligibility_lead_provider: EligibilityLeadProviderStep,
            email_address: EmailAddressStep,
            find_mentor: FindMentorStep,
            lead_provider: LeadProviderStep,
            mentoring_at_new_school_only: MentoringAtNewSchoolOnlyStep,
            national_insurance_number: NationalInsuranceNumberStep,
            no_trn: NoTRNStep,
            not_found: NotFoundStep,
            previous_training_period_details: PreviousTrainingPeriodDetailsStep,
            programme_choices: ProgrammeChoicesStep,
            review_mentor_details: ReviewMentorDetailsStep,
            review_mentor_eligibility: ReviewMentorEligibilityStep,
            started_on: StartedOnStep,
            trn_not_found: TRNNotFoundStep,
          }
        ]
      end

      def self.step?(step_name) = Array(steps).first[step_name].present?

      delegate :save!, to: :current_step
      delegate :reset, to: :mentor

      def ect = @ect ||= ECTAtSchoolPeriod.find(ect_id)

      def allowed_steps
        @allowed_steps ||=
          begin
            return [:confirmation] if mentor.registered

            steps = %i[find_mentor]
            return %i[no_trn] + steps unless [mentor.trn, mentor.date_of_birth].all?
            return steps + %i[trn_not_found] unless mentor.national_insurance_number || mentor.in_trs?
            return steps + %i[cannot_mentor_themself] if mentor.trn == ect.trn

            unless mentor.matches_trs_dob?
              steps << :national_insurance_number
              return steps unless mentor.national_insurance_number
              return steps + %i[not_found] unless mentor.in_trs?
            end

            if mentor.active_at_school?
              steps << :already_active_at_school
              return steps unless mentor.already_active_at_school

              return [:confirmation]
            end

            return steps + %i[cannot_register_mentor] if mentor.prohibited_from_teaching?

            steps << :review_mentor_details
            return steps unless mentor.change_name

            steps << :email_address
            return steps unless mentor.email
            return steps + %i[change_email_address cant_use_changed_email cant_use_email] if mentor.email_taken?

            steps << if mentor.currently_mentor_at_another_school?
                       :mentoring_at_new_school_only
                     else
                       :started_on
                     end

            steps << :started_on if mentor.mentoring_at_new_school_only == "yes" || mentor.previous_school_closed_mentor_at_school_periods?
            steps << :previous_training_period_details if mentor.eligible_for_funding? || mentor.provider_led_ect?
            steps << :programme_choices unless mentor.became_ineligible_for_funding?
            steps << :lead_provider unless mentor.use_same_programme_choices == "yes"
            steps << :review_mentor_eligibility if mentor.funding_available?
            steps << :eligibility_lead_provider if mentor.funding_available?
            steps += %i[change_mentor_details change_email_address check_answers]
            steps << :change_started_on if mentor.started_on
            steps << :change_lead_provider if mentor.lead_provider

            steps
          end
      end

      def mentor
        @mentor ||= RegistrationSession.new(store)
      end
    end
  end
end
