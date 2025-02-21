module Schools
  module RegisterMentorWizard
    class Wizard < DfE::Wizard::Base
      attr_accessor :current_user, :store, :ect_id

      steps do
        [
          {
            already_active_at_school: AlreadyActiveAtSchoolStep,
            cannot_mentor_themself: CannotMentorThemselfStep,
            cannot_register_mentor: CannotRegisterMentorStep,
            change_email_address: ChangeEmailAddressStep,
            change_mentor_details: ChangeMentorDetailsStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
            email_address: EmailAddressStep,
            find_mentor: FindMentorStep,
            national_insurance_number: NationalInsuranceNumberStep,
            not_found: NotFoundStep,
            no_trn: NoTRNStep,
            review_mentor_details: ReviewMentorDetailsStep,
            trn_not_found: TRNNotFoundStep,
          }
        ]
      end

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      delegate :save!, to: :current_step
      delegate :reset, to: :mentor

      def ect
        @ect ||= ECTAtSchoolPeriod.find(ect_id)
      end

      def mentor
        @mentor ||= Mentor.new(store)
      end
    end
  end
end
