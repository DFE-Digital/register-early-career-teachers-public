module Schools
  module RegisterECTWizard
    class NationalInsuranceNumberStep < Step
      attr_accessor :national_insurance_number

      validates :national_insurance_number, national_insurance_number: true

      def self.permitted_params
        %i[national_insurance_number]
      end

      def next_step
        return :not_found unless ect.in_trs?
        return :induction_completed if ect.induction_completed?
        return :induction_exempt if ect.induction_exempt?
        return :induction_failed if ect.induction_failed?

        :review_ect_details
      end

      def previous_step
        :find_ect
      end

    private

      def persist
        ect.update(national_insurance_number:,
                   trs_date_of_birth: trs_teacher.date_of_birth,
                   trs_national_insurance_number: trs_teacher.trs_national_insurance_number,
                   trs_first_name: trs_teacher.trs_first_name,
                   trs_last_name: trs_teacher.trs_last_name,
                   trs_induction_status: trs_teacher.trs_induction_status,
                   prohibited_from_teaching: trs_teacher.prohibited_from_teaching?)
      end

      def trs_teacher
        @trs_teacher ||= fetch_trs_teacher(trn: ect.trn, national_insurance_number:)
      end
    end
  end
end
