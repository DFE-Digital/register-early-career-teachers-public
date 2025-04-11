module Schools
  module RegisterMentorWizard
    class Wizard < ApplicationWizard
      attr_accessor :store, :ect_id

      steps do
        [
          {
            already_active_at_school: AlreadyActiveAtSchoolStep,
            cannot_mentor_themself: CannotMentorThemselfStep,
            cannot_register_mentor: CannotRegisterMentorStep,
            cant_use_changed_email: CantUseChangedEmailStep,
            cant_use_email: CantUseEmailStep,
            change_email_address: ChangeEmailAddressStep,
            change_mentor_details: ChangeMentorDetailsStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
            email_address: EmailAddressStep,
            find_mentor: FindMentorStep,
            national_insurance_number: NationalInsuranceNumberStep,
            no_trn: NoTRNStep,
            not_found: NotFoundStep,
            review_mentor_details: ReviewMentorDetailsStep,
            review_mentor_eligibility: ReviewMentorEligibilityStep,
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

            return steps + %i[cannot_register_mentor] if mentor.prohibited_from_teaching

            steps << :review_mentor_details
            return steps unless mentor.change_name

            steps << :email_address
            return steps unless mentor.email
            return steps + %i[change_email_address cant_use_changed_email cant_use_email] if mentor.cant_use_email?

            steps << :review_mentor_eligibility if mentor.funding_available?
            steps += %i[change_mentor_details change_email_address check_answers]

            steps
          end
      end

      def mentor
        @mentor ||= Mentor.new(store)
      end
    end
  end
end
