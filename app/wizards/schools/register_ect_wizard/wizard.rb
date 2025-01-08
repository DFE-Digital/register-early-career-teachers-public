# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class Wizard < DfE::Wizard::Base
      attr_accessor :store, :school

      steps do
        [
          {
            appropriate_body: AppropriateBodyStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
            email_address: EmailAddressStep,
            find_ect: FindECTStep,
            funding_ind_appropriate_body: FundingIndAppropriateBodyStep,
            induction_completed: InductionCompletedStep,
            induction_exempt: InductionExemptStep,
            national_insurance_number: NationalInsuranceNumberStep,
            not_found: NotFoundStep,
            programme_type: ProgrammeTypeStep,
            review_ect_details: ReviewECTDetailsStep,
            start_date: StartDateStep,
            trn_not_found: TRNNotFoundStep,
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
    end
  end
end
