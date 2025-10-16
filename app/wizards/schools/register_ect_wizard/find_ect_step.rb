module Schools
  module RegisterECTWizard
    class FindECTStep < Step
      attr_accessor :trn, :date_of_birth

      validates :trn,
                teacher_reference_number: true,
                presence: { message: 'Enter the teacher reference number (TRN)' }
      validates :date_of_birth, date_of_birth: true

      def self.permitted_params
        %i[trn date_of_birth]
      end

      def next_step
        return :trn_not_found unless ect.in_trs?
        return :national_insurance_number unless ect.matches_trs_dob?
        return :already_active_at_school if ect.active_at_school?(school.urn)
        return :induction_completed if ect.induction_completed?
        return :induction_exempt if ect.induction_exempt?
        return :induction_failed if ect.induction_failed?
        return :cannot_register_ect if ect.prohibited_from_teaching?

        :review_ect_details
      end

    private

      def persist
        ect.update(trn: formatted_trn,
                   date_of_birth: date_of_birth.values.join("-"),
                   trs_national_insurance_number: trs_teacher.trs_national_insurance_number,
                   **trs_teacher.to_h)
      end

      def trs_teacher
        @trs_teacher ||= fetch_trs_teacher(trn: formatted_trn)
      end

      def formatted_trn
        @formatted_trn ||= Validation::TeacherReferenceNumber.new(trn).formatted_trn
      end

      def pre_populate_attributes
        self.trn = ect.trn
        self.date_of_birth = Schools::Validation::DateOfBirth.new(ect.date_of_birth).date_as_hash
      end
    end
  end
end
