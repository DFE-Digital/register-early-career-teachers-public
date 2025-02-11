# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class FindECTStep < Step
      attr_accessor :trn, :date_of_birth

      validates :trn, teacher_reference_number: true
      validates :date_of_birth, date_of_birth: true

      def self.permitted_params
        %i[trn date_of_birth]
      end

      def next_step
        return :trn_not_found unless ect.in_trs?
        return :national_insurance_number unless ect.matches_trs_dob?
        return :already_active_at_school if ect.active_at_school?(school:)
        return :induction_completed if ect.induction_completed?
        return :induction_exempt if ect.induction_exempt?
        return :cannot_register_ect if trs_teacher.prohibited_from_teaching?

        :review_ect_details
      end

      def date_of_birth=(value)
        if value.is_a?(String)
          # Convert dates read from the store
          @date_of_birth = string_to_date_hash(value)
        elsif value.is_a?(Hash)
          # Assign directly if it's a hash
          @date_of_birth = value
        end
      end

    private

      def persist
        ect.update(trn: formatted_trn,
                   date_of_birth: date_of_birth.values.join("-"),
                   trs_national_insurance_number: trs_teacher.national_insurance_number,
                   trs_date_of_birth: trs_teacher.date_of_birth,
                   trs_trn: trs_teacher.trn,
                   trs_first_name: trs_teacher.first_name,
                   trs_last_name: trs_teacher.last_name,
                   trs_induction_status: trs_teacher.induction_status)
      end

      def trs_teacher
        @trs_teacher ||= fetch_trs_teacher(trn: formatted_trn)
      end

      def formatted_trn
        @formatted_trn ||= Validation::TeacherReferenceNumber.new(trn).formatted_trn
      end

      def string_to_date_hash(date_string)
        # Parse the string to extract the month and year
        date = Date.parse(date_string)

        # Return the hash in the desired format
        { 3 => date.day, 2 => date.month, 1 => date.year }
      end
    end
  end
end
