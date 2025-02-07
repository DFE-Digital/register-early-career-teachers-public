module Schools
  module RegisterMentorWizard
    class Wizard < DfE::Wizard::Base
      attr_accessor :store, :ect_id

      include Rails.application.routes.url_helpers

      steps do
        [
          {
            already_active_at_school: AlreadyActiveAtSchoolStep,
            cannot_mentor_themself: CannotMentorThemselfStep,
            cannot_register_mentor: CannotRegisterMentorStep,
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

      # 3.
      def next_step_path(current_step)
        return schools_register_mentor_wizard_check_answers_path if cya?(current_step)

        super()
      end

      def back_link_path(current_step)
        return schools_register_mentor_wizard_check_answers_path if cya?(current_step)
          
        case current_step
        when :review_mentor_details then schools_register_mentor_wizard_find_mentor_path
        when :email_address then schools_register_mentor_wizard_review_mentor_details_path
        end
      end

      # private

      # 2 & 3.
      def cya?(current_step)
        %i[
          review_mentor_details
          email_address
        ].include?(current_step) && mentor.email.present?
      end
    end
  end
end
