module Schools
  module RegisterMentor
    class Wizard < DfE::Wizard::Base
      attr_accessor :store

      steps do
        [
          {
            cannot_without_trn: CannotWithoutTRNStep,
            find_mentor: FindMentorStep,
            national_insurance_number: NationalInsuranceNumberStep,
            not_found: NotFoundStep,
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

      def mentor
        @mentor ||= Mentor.new(store)
      end
    end
  end
end
